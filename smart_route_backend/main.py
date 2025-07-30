# main.py
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from neo4j import GraphDatabase
from typing import List
from fastapi.responses import JSONResponse

# --- Pydantic Models for Request Body ---
class Coordinate(BaseModel):
    lat: float
    lng: float

class RouteRequest(BaseModel):
    origin: Coordinate
    destination: Coordinate

# --- FastAPI App Initialization ---
app = FastAPI(
    title="Smart Route Planner API",
    description="Finds the optimal route between two points using Neo4j graph algorithms."
)

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Neo4j Connection ---
# --- MODIFIED: Removed local fallback to ensure cloud variables are used ---
# This code will now only read from the environment variables set by Cloud Run.
NEO4J_URI = os.environ.get("NEO4J_URI")
NEO4J_USER = "neo4j" # Default user for AuraDB
NEO4J_PASSWORD = os.environ.get("NEO4J_PASSWORD")

# Add a check to ensure the variables were loaded correctly
if not NEO4J_URI or not NEO4J_PASSWORD:
    raise ValueError("FATAL: NEO4J_URI and NEO4J_PASSWORD environment variables were not found.")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))


# --- Neo4j Query Functions ---
def find_closest_node(tx, lat, lng):
    """Find the closest :Location node to a given lat/lng coordinate."""
    query = """
    MATCH (n:Location)
    WITH n, point.distance(
        point({latitude: $lat, longitude: $lng}),
        point({latitude: n.lat, longitude: n.lng})
    ) AS dist
    RETURN n
    ORDER BY dist
    LIMIT 1
    """
    result = tx.run(query, lat=lat, lng=lng)
    record = result.single()
    return record[0] if record else None

def get_shortest_path(tx, origin_node_id, dest_node_id):
    """Calculate the shortest path using Dijkstra's algorithm."""
    query = """
    MATCH (start:Location), (end:Location)
    WHERE elementId(start) = $origin_id AND elementId(end) = $dest_id
    CALL apoc.algo.dijkstra(start, end, 'ROAD', 'weight') YIELD path, weight
    RETURN [node in nodes(path) | {lat: node.lat, lng: node.lng}] AS route
    """
    result = tx.run(query, origin_id=origin_node_id, dest_id=dest_node_id)
    record = result.single()
    return [dict(p) for p in record["route"]] if record and record["route"] else []

# --- API Endpoint ---
@app.post("/route")
def get_optimized_route(req: RouteRequest):
    """
    Receives origin and destination coordinates, finds the closest nodes in the graph,
    calculates the shortest path, and returns the list of coordinates for the route.
    """
    with driver.session() as session:
        origin_node = session.read_transaction(find_closest_node, req.origin.lat, req.origin.lng)
        dest_node = session.read_transaction(find_closest_node, req.destination.lat, req.destination.lng)

        if not origin_node or not dest_node:
            return JSONResponse(content=[])

        route_coordinates = session.read_transaction(get_shortest_path, origin_node.element_id, dest_node.element_id)
        return JSONResponse(content=route_coordinates)

# --- To run the server ---
# Use the command: uvicorn main:app --reload
