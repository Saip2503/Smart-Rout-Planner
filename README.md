# Smart Route Planner

_Intelligent routing beyond the shortest path, powered by Neo4j and Google Maps._

![Smart Route Planner Thumbnail](https://i.imgur.com/uRcNt56.png)

## About The Project

**Smart Route Planner** is a full-stack mobile application that calculates the most efficient travel path between two points using graph-based logic. Unlike typical GPS apps, our solution uses a **Neo4j** graph database on the backend to model a road network, allowing for complex, weighted pathfinding based on more than just distance.

The **Flutter** app provides a clean user interface on Google Maps where users can select their origin and destination, choose a travel mode, and view a detailed, road-snapped route along with its estimated distance and duration.

### Key Features

* **Graph-Powered Backend:** Utilizes a Neo4j database to find optimal paths using Dijkstra's algorithm.
* **Interactive Map UI:** A smooth, responsive map interface built with Flutter and the Google Maps SDK.
* **Road-Snapped Polylines:** Fetches detailed turn-by-turn routes from the Google Directions API for a polished user experience.
* **Travel Mode Selection:** Supports routing for Driving, Walking, and Bicycling.
* **Route Information:** Displays the total distance and estimated duration for the calculated route.
* **Secure Configuration:** Uses `.env` files to securely manage API keys.

---

## Built With

This project was built with a modern, full-stack approach:

* **Frontend:**
    * [Flutter](https://flutter.dev/)
    * [Dart](https://dart.dev/)
* **Backend:**
    * [Python 3](https://www.python.org/)
    * [FastAPI](https://fastapi.tiangolo.com/)
* **Database:**
    * [Neo4j](https://neo4j.com/) (with APOC Plugin)
* **APIs & Services:**
    * [Google Maps SDK for Flutter](https://pub.dev/packages/Maps_flutter)
    * [Google Directions API](https://developers.google.com/maps/documentation/directions/overview)
    * [flutter_polyline_points](https://pub.dev/packages/flutter_polyline_points)

---

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

Make sure you have the following software installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Python 3.10+](https://www.python.org/downloads/)
* [Neo4j Desktop](https://neo4j.com/download/)
* An IDE like VS Code with Flutter & Python extensions.

### Backend Setup

1.  **Clone the repo**
    ```sh
    git clone [https://github.com/your_username/smart_route_planner.git](https://github.com/your_username/smart_route_planner.git)
    cd smart_route_planner/smart_route_backend
    ```
2.  **Install Python packages**
    ```sh
    pip install -r requirements.txt
    ```
3.  **Setup Neo4j**
    * Open Neo4j Desktop and create a new database.
    * Start the database, then go to the "Plugins" tab and **install the APOC plugin**.
    * Open the Neo4j Browser and run the Cypher script in `seed_data.cypher` to populate the graph.
    * Restart the database.
4.  **Update Credentials**
    * Open `main.py` and update the `AUTH` variable with your Neo4j password.
    ```python
    AUTH = ("neo4j", "your_neo4j_password")
    ```
5.  **Run the Backend Server**
    ```sh
    uvicorn main:app --reload
    ```
    The server will be running at `http://127.0.0.1:8000`.

### Frontend Setup

1.  **Navigate to the Flutter project**
    ```sh
    cd ../smart_route_planner_flutter # from the backend directory
    ```
2.  **Get a Google Maps API Key**
    * Go to the [Google Cloud Console](https://console.cloud.google.com/).
    * Create a new project.
    * Enable the **Maps SDK for Android**, **Maps SDK for iOS**, and the **Directions API**.
    * Create and copy your API key.
3.  **Configure API Keys**
    * **Create `.env` file:** In the root of the Flutter project, create a file named `.env` and add your key:
        ```
        Maps_API_KEY=YOUR_API_KEY_HERE
        ```
    * **Android:** Add the key to `android/app/src/main/AndroidManifest.xml`:
        ```xml
        <application ...>
            <meta-data android:name="com.google.android.geo.API_KEY"
                       android:value="YOUR_API_KEY_HERE"/>
            ...
        </application>
        ```
    * **(Optional) iOS:** Add the key to `ios/Runner/AppDelegate.swift`.
4.  **Install Flutter packages**
    ```sh
    flutter pub get
    ```
5.  **Run the app**
    ```sh
    flutter run
    ```

---

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.
