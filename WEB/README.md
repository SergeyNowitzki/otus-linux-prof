# otus-linux-proffesional
## TASK 27: Deploying WEB app: Nginx - Wordpress - Flask - Node.js

Dynamic Web Compose is a Docker-based project that integrates a WordPress site, a Flask application, and a Node.js application, orchestrated using Docker Compose. This setup leverages MySQL for the database and Nginx as a reverse proxy to manage requests to different services.

### Project Structure
```
dynamic_web_compose/
├── .env
├── docker-compose.yaml
├── flask-app
│   ├── Dockerfile
│   ├── __pycache__
│   ├── main.py
│   └── requirements.txt
├── nginx-conf
│   └── nginx.conf
└── node-app
    ├── Dockerfile
    ├── package.json
    └── server.js
```
### Deploying the project
`docker-compose up -d --build`

```
docker ps
CONTAINER ID   IMAGE                               COMMAND                  CREATED          STATUS          PORTS                    NAMES
0d4da458312b   nginx:1.22.0-alpine                 "/docker-entrypoint.…"   33 seconds ago   Up 31 seconds   0.0.0.0:80->80/tcp       webserver
ea5ccdf6ec83   wordpress:6.0.1-php8.0-fpm-alpine   "docker-entrypoint.s…"   33 seconds ago   Up 32 seconds   9000/tcp                 wordpress
ba991614451c   flask-app:latest                    "gunicorn --bind 0.0…"   33 seconds ago   Up 32 seconds   0.0.0.0:5001->5001/tcp   flask
ba681b61c7e6   node-app:latest                     "docker-entrypoint.s…"   33 seconds ago   Up 32 seconds   0.0.0.0:3000->3000/tcp   node
8396147391c3   mysql:8.0                           "docker-entrypoint.s…"   33 seconds ago   Up 32 seconds   3306/tcp, 33060/tcp      db
```


### Access the applications:
WordPress: http://localhost
<img width="1167" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/98f26693-0422-406a-803e-4d01cfbd179d">


Flask: http://localhost/flask
<img width="1000" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/72b7bf96-18dd-40f8-af1b-935f2c218635">


NodeJs: http://localhost/node

<img width="991" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/7833d80e-71d0-4632-b52b-7abce0f1e95f">

