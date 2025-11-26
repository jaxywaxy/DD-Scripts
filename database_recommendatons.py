import requests
import csv

# Replace with your actual Datadog API and Application keys
API_KEY = '892f6631c805d4aa6396397b72fbd4d7'
APP_KEY = 'd95cf56d69c5b07b2ca246e1b323e233a800dcde'

# Datadog API endpoint for database recommendations
url = 'https://api.ap2.datadoghq.com/api/v1/databases/recommendations'

# Set up headers for authentication
headers = {
    'DD-API-KEY': API_KEY,
    'DD-APPLICATION-KEY': APP_KEY,
    'Content-Type': 'application/json'
}

# Make the API request
response = requests.get(url, headers=headers)

# Check if the request was successful
if response.status_code == 200:
    recommendations = response.json()

    # Open a CSV file to write the results
    with open('db_recommendations.csv', mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        # Write header
        writer.writerow(['Recommendation Type', 'Severity', 'Database Name', 'Host', 'Description'])

        # Write each recommendation to the CSV
        for rec in recommendations.get('data', []):
            rec_type = rec.get('type', '')
            severity = rec.get('severity', '')
            db_name = rec.get('database_name', '')
            host = rec.get('host', '')
            description = rec.get('description', '')
            writer.writerow([rec_type, severity, db_name, host, description])

    print("Database recommendations exported to db_recommendations.csv")
else:
    print(f"Failed to fetch recommendations. Status code: {response.status_code}")
    print(response.text)

