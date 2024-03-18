# otus-linux-proffesional
## TASK 14: Docker - Creating a custom nginx image

### Docker file spining up the nginx container
#### Dockerfile description:
`FROM` The `FROM` instruction sets the base image for subsequent instructions
`COPY` Both `COPY` and `ADD` are Dockerfile instructions used to copy files from the Docker host into the container. Besides copying local files, `ADD` can also fetch remote URLs and extract tar archives from URLs or local files.
`EPOSE` Docker uses this information to interconnect containers using links and to set up port redirection on the host system.
`VOLUME` instruction is specifying a directory where Nginx will store its data at runtime, such as logs or temporary files.
`CMD` instruction is used to specify the default command that should be executed when a container starts.

#### This command builds the Docker image with the tag my_nginx_image from the current directory (where the Dockerfile is located).
`docker build -t my_nginx_image .`

The list of images can be displaid by command: 
`docker image ls`

#### Once the image is built, you can run a container from it using the following command:
```
docker run -d -p 8080:80 --name my_nginx_container\
 -v nginx_data:/var/www/html\
 -v ./files/nginx.conf:/etc/nginx/nginx.conf my_nginx_image
```

Explanation:
`-d`: Detached mode (runs the container in the background)
`-p 8080:80`: Maps port 8080 on the host to port 80 in the container
`--name my_nginx_container`: Names the container as my_nginx_container
`-v nginx_data:/var/www/html`: Mounts the named volume nginx_data to the directory `/var/www/html` in the container
`my_nginx_image`: Specifies the image to run the container from
With this command, your Nginx container will be up and running, and you can access it through `http://localhost:8080` in your web browser.
```
docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED             STATUS             PORTS                            NAMES
666e049f721f   my_nginx_image   "/docker-entrypoint.…"   About an hour ago   Up About an hour   8080/tcp, 0.0.0.0:8080->80/tcp   my_nginx_container
```

Check the connection to the container:
```
curl http://localhost:8080
<html>
    <head>
        <title>My TEST OTUS LAB Webpage</title>
    </head>
    <body>
        <h1>NGINX Docker LAB</h1>
        <p>LAB 14</p>
    </body>

    <img src="otus.png" width=500/>
</html>
```

The named volume ensures that the HTML files are stored persistently and managed by Docker, simplifying data sharing and management.
The host volume allows us to manage the Nginx configuration file directly on the host machine, providing control and easy access for modifications.
Directory of volumes:
`/var/lib/docker/volumes`
To display list of volumes which are attached to the containers.
`docker inspect <container-id> --format='{{.Mounts}}' `

#### Removing resources
To remove container
`docker rm -f <container-id>`
To remove volume
`docker volume rm <volume-id>`
To remove image
```
docker image ls
docker rmi <image-id>
```

#### Docker-Compose Custom Redmine:
The `build` section in a Docker Compose file allows to specify instructions for building a custom Docker image.
This section is typically used when we want to build a custom image for our service instead of using an existing image from Docker Hub.

A `Dockerfile` is needed to be created in the same directory as the `docker-compose.yml` file to build the Redmine image with the custom theme.

After creating the `docker-compose.yml` and `Dockerfile`, you can run `docker-compose up --build` to build the Redmine image and start the containers.

Theme:
https://github.com/mrliptontea/PurpleMine2/blob/master/README.md
To install PurpleMine, just download .zip and unpack it to your Redmine's public/themes folder.
Then go to Redmine > Administration > Settings > Display and select PurpleMine2 from the list and save the changes.

http://loaclhost:3000
<img width="1327" alt="Redmine_theme_bl" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/84a515c2-0072-45a2-8e92-9a2a83d96ae7">
