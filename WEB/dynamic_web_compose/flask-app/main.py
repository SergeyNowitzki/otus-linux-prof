from flask import Flask, request
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)

# Trust X-Forwarded-* headers. You can adjust the values based on your setup.
# num_proxies=1 means we trust only one proxy (Nginx in this case)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_port=1, x_prefix=1)


@app.route('/')
def hello_world():
    user_agent = request.headers.get('User-Agent')
    client_ip = request.remote_addr
    return f"Hello from Flask!<br>Your User-Agent is: {user_agent}<br>Your IP address is: {client_ip}"

@app.errorhandler(500)
def internal_error(error):
    return "500 error", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5001)