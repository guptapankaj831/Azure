"""
Question:
You are building an Azure Function that is triggered by an HTTP GET request. 
The function needs to return a list of all active users from a database in JSON format. 
If no users are found, the function should return a 404 Not Found response with a message "No users found."

How would you implement this in the Azure Function?
"""

import azure.functions as func
import logging
import json
from azure.cosmos import CosmosClient, exceptions
import os

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Cosmos DB settings
COSMOS_ENDPOINT = os.environ["COSMOS_DB_URL"]
COSMOS_KEY = os.environ["COSMOS_DB_KEY"]
COSMOS_DATABASE = os.environ["COSMOS_DB_NAME"]
COSMOS_CONTAINER = os.environ["COSMOS_CONTAINER_NAME"]

@app.route(route="get_user_details")
def get_user_details(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        # Get active users from Cosmos DB
        active_users = get_active_users()

        if not active_users:
            # If no active users found, return 404
            return func.HttpResponse(
                json.dumps({"message": "No users found."}),
                status_code=404,
                mimetype="application/json"
            )

        # If users found, return them as a JSON response
        return func.HttpResponse(
            json.dumps(active_users),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"message": "An error occurred while fetching users."}),
            status_code=500,
            mimetype="application/json"
        )

# Function to fetch active users from CosMosDB
def get_active_users():
    # Initialize Cosmos DB Client
    client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
    container = client.get_database_client(COSMOS_DATABASE).get_container_client(COSMOS_CONTAINER)

    query = "SELECT * FROM c WHERE c.isActive = true"
    users = []

    try:
        # Query Cosmos DB for active users
        items = container.query_items(query=query, enable_cross_partition_query=True)

        # Collect the active users
        for item in items:
            users.append(item)

    except exceptions.CosmosHttpResponseError as e:
        logging.error(f"Error querying Cosmos DB: {e.message}")
        raise

    return users
