from app import app
from flask import jsonify, Blueprint, request

# favicon, sitemap, index go here

@app.route('/')
def main_page():
    return jsonify('if you can see this, the flask app is working! yay!')

@app.route('/login')
def login():
    return jsonify('This is login')
