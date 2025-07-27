import osmnx as ox
from neo4j import GraphDatabase

# Step 1: Load road network from OSM
city = "Mumbai, India"  # Change to "India" later
G = ox.graph_from_place(city, network_type="drive")

# Step 2: Neo4j connection
driver = GraphDatabase.driver("neo4j://127.0.0.1:7687", auth=("neo4j", "saipawar25"))

def clear_graph(tx):
    tx.run("MATCH (n) DETACH DELETE n")

def import_graph(tx, G):
    # Add all nodes
    for node, data in G.nodes(data=True):
        tx.run(
            "CREATE (n:Location {id: $id, lat: $lat, lng: $lng})",
            id=node,
            lat=data['y'],
            lng=data['x']
        )

    # Add all edges
    for u, v, data in G.edges(data=True):
        tx.run("""
            MATCH (a:Location {id: $u}), (b:Location {id: $v})
            CREATE (a)-[:ROAD {weight: $weight}]->(b)
        """, u=u, v=v, weight=data.get("length", 1.0))

# Step 3: Run it
with driver.session() as session:
    session.write_transaction(clear_graph)
    session.write_transaction(import_graph, G)

print("✅ Import completed.")
