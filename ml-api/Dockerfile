# Use an official Python runtime as a base image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy requirements and install them
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your cod
COPY . .

# Expose port 5001 (or whatever port your Flask app uses)
EXPOSE 5001

# Set environment variable for Flask
ENV FLASK_APP=app.py
ENV FLASK_RUN_PORT=5001

# Run the app
CMD ["flask", "run", "--host=0.0.0.0", "--port=5001"]
