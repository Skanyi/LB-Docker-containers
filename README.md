Task Flow
Task 1:
The application itself
`from flask import Flask
 app = Flask(__name__)

 @app.route('/')
 def hello_world():
     return 'Hello, World'

 if __name__ == '__main__':
     app.run(debug=True, host='0.0.0.0')`

Start by creating the Dockerfile
`FROM python:3.7.0-alpine3.8
 COPY . /app
 WORKDIR /app
 RUN pip install flask
 ENTRYPOINT ["python3"]
 CMD ["main.py"]`

Build the image
`docker build -t hello .`

Run the image
`docker run -d -p 5000:5000 -m 20m --restart always hello`

That means the image will be run on the background on port 5000 and the memory allocation is 20m and always restart. The docker deamon will always try to restart the container regardless of the exit status. 

Task 2:
Read the env varible and substitute it
`docker run -d -p 5000:5000 -m 20m --restart always -e GREET="andela" hello`

I updated the python app to this
`import os
 from flask import Flask
 app = Flask(__name__)

 @app.route('/')
 def hello_world():
     return 'Hello, {}'.format(os.getenv('GREET'))

 if __name__ == '__main__':
     app.run(debug=True, host='0.0.0.0')`

From there, you can pass any value to the GREET variable. 

Task 3:
Run 2 docker containers
`docker run -d -p 5000:5000 -m 20m --restart always -e NAME="world" hello`
`docker run -d -p 5001:5000 -m 20m --restart always -e NAME="andela" hello`

Here there are two containers running on port 5000 and 5001

Task 4:
Setup Load balance using round robin

Start by creating a haproxy image 
`FROM haproxy:1.7
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg`

Then create a haproxy.cfg that loadbalance the servers
`global
        debug

defaults
        log global
        mode http
        option httplog
        timeout connect 5000
        timeout client 5000
        timeout server 5000

frontend main
        bind 0.0.0.0:5000
        default_backend app

backend app
        balance roundrobin
        mode http
        option httpchk
        option forwardfor
        option http-server-close
        server srv1 app_one
        server srv2 app_two

listen stats
	    bind *:9201
        stats enable
        stats uri /stats
        stats realm Strictly\ Private
        stats auth kanyi:haproxypass`

Then create a docker-compose.yml file to launch all the 3 servers at the same time
`version: '3'

services:
  app_one:
    image: hello
    ports:
      - 5001:5000
    env_file:
        - .env
    networks:
        public_net:
            ipv4_address: "${APP_ONE_IP}"
    environment:
      - GREET=world
    container_name: 'app_one'

  app_two:
    image: hello
    ports:
      - 5002:5000
    env_file:
        - .env
    networks:
        public_net:
            ipv4_address: "${APP_TWO_IP}"
    environment:
       - GREET=andela
    container_name: 'app_two'

  haproxy:
    image: haproxy-svc
    ports:
      - 5000:5000
      - 9201:9201
    env_file:
        - .env
    networks:
            public_net:
                ipv4_address: "${HAPROXY_IP}"
    container_name: 'haproxy'

networks:
    public_net:
        driver: bridge
        ipam:
            driver: default
            config:
                - subnet: ${NETWORK_SUBNET}`

