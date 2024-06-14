#!/bin/sh
#export FLASK_APP=./app.py
#export FLASK_DEBUG=1
#flask run -h 0.0.0.0

# Ensure all dependencies are installed
pip install -r requirements.txt

# Export necessary environment variables
export FLASK_APP=app.py
export FLASK_RUN_HOST=0.0.0.0
export FLASK_RUN_PORT=8080

# Start the Flask application
flask run