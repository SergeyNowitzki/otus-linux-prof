FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt main.py /app/

# Install the dependencies
RUN pip install -r requirements.txt
# Install Gunicorn
RUN pip install gunicorn

# Define environment variable for the Flask app
ENV FLASK_APP=main.py

# Make port 5000 available to the world outside this container
EXPOSE 5001

# Run Gunicorn when the container launches
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "main:app"]