# Use an official Python runtime as a base image
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Cloud Run requires the app to listen on port 8080
EXPOSE 8080

ENV FLASK_APP=app.py
ENV FLASK_RUN_PORT=8080

CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]
