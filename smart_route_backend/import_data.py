# import_data.py
import os
import osmnx as ox
from neo4j import GraphDatabase

# --- Neo4j Connection ---
# Reads credentials from environment variables
NEO4J_URI = os.environ.get("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = "neo4j"
NEO4J_PASSWORD = os.environ.get("NEO4J_PASSWORD", "your_local_password")

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

def clear_graph(tx):
    print("Clearing existing graph...")
    tx.run("MATCH (n) DETACH DELETE n")

# --- MODIFIED: Split schema and write operations into separate functions ---

def create_constraints(tx):
    """Creates schema constraints in its own transaction."""
    print("Creating schema constraints...")
    tx.run("CREATE CONSTRAINT location_id IF NOT EXISTS FOR (n:Location) REQUIRE n.id IS UNIQUE")

def import_nodes_and_roads(tx, G):
    """Imports all nodes and roads in a data writing transaction."""
    # Import all nodes from the OSMnx graph
    print("Importing nodes...")
    for node, data in G.nodes(data=True):
        tx.run(
            "CREATE (n:Location {id: $id, lat: $lat, lng: $lng})",
            id=node,
            lat=data['y'],
            lng=data['x']
        )

    # Import all edges (roads)
    print("Importing roads...")
    for u, v, data in G.edges(data=True):
        tx.run("""
            MATCH (a:Location {id: $u}), (b:Location {id: $v})
            CREATE (a)-[:ROAD {weight: $weight}]->(b)
        """, u=u, v=v, weight=data.get("length", 1.0))

# --- Main Execution ---
if __name__ == "__main__":
    try:
        # Step 1: Load road network from OpenStreetMap
        city = "Navi Mumbai, India" 
        print(f"Downloading road network for {city}...")
        G = ox.graph_from_place(city, network_type="drive")

        # Step 2: Run the import transactions
        with driver.session() as session:
            # --- MODIFIED: Use execute_write and separate transactions ---
            session.execute_write(clear_graph)
            session.execute_write(create_constraints) # First transaction for schema
            session.execute_write(import_nodes_and_roads, G) # Second transaction for data

        print("✅ Graph import completed successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        driver.close()
