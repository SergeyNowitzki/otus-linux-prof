# Use Nginx Alpine as base image
FROM nginx:alpine

# Copy custom picture
COPY files/otus.png /var/www/html/otus.png

# Copy custom index.html file
COPY files/index.html /var/www/html/index.html

# Expose port 8080
EXPOSE 8080

# Define a named volume for Nginx data
VOLUME ["/usr/share/nginx/html"]

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]