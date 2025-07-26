# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from neo4j import GraphDatabase
from typing import List

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
# Allows your Flutter app to make requests to this backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# --- Neo4j Connection ---
# IMPORTANT: Replace with your Neo4j credentials
URI = "bolt://localhost:7687"
AUTH = ("neo4j", "your_password")
driver = GraphDatabase.driver(URI, auth=AUTH)

# --- Neo4j Query Functions ---
def find_closest_node(tx, lat, lng):
    """Find the closest :Location node to a given lat/lng coordinate."""
    query = """
    MATCH (n:Location)
    WITH n, distance(
        point({latitude: $lat, longitude: $lng}),
        point({latitude: n.lat, longitude: n.lng})
    ) AS dist
    RETURN n
    ORDER BY dist
    LIMIT 1
    """
    result = tx.run(query, lat=lat, lng=lng)
    return result.single()[0]

def get_shortest_path(tx, origin_node_id, dest_node_id):
    """Calculate the shortest path using Dijkstra's algorithm."""
    query = """
    MATCH (start:Location), (end:Location)
    WHERE id(start) = $origin_id AND id(end) = $dest_id
    CALL apoc.algo.dijkstra(start, end, 'ROAD', 'weight') YIELD path, weight
    // Return the list of nodes in the path
    RETURN [node in nodes(path) | {lat: node.lat, lng: node.lng}] AS route
    """
    result = tx.run(query, origin_id=origin_node_id, dest_id=dest_node_id)
    record = result.single()
    return record["route"] if record else []

# --- API Endpoint ---
@app.post("/route", response_model=List[Coordinate])
def get_optimized_route(req: RouteRequest):
    """
    Receives origin and destination coordinates, finds the closest nodes in the graph,
    calculates the shortest path, and returns the list of coordinates for the route.
    """
    with driver.session() as session:
        # Find the graph node IDs closest to the requested lat/lng points
        origin_node = session.read_transaction(find_closest_node, req.origin.lat, req.origin.lng)
        dest_node = session.read_transaction(find_closest_node, req.destination.lat, req.destination.lng)

        if not origin_node or not dest_node:
            return []

        # Calculate the shortest path between these two node IDs
        route_coordinates = session.read_transaction(get_shortest_path, origin_node.id, dest_node.id)
        return route_coordinates

# --- To run the server ---
# Use the command: uvicorn main:app --reload