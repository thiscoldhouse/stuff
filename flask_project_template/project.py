# add project root to path
import sys
import os

PROJECT_ROOT = os.path.dirname(os.path.realpath(__file__))
sys.path.append(PROJECT_ROOT)


# -------- dev or prod ----------- #
env = 'LOCAL'
if os.environ.get('ENV') == 'PROD':
    env = 'PROD'
elif os.environ.get('ENV') == 'PENTEST':
    env = 'PENTEST'
elif os.environ.get('ENV') == 'STAGING':
    env = 'STAGING'
elif os.environ.get('ENV') == 'DEV':
    env = 'DEV'

# -------- setup flask app ------- #
from flask import Flask
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)


# ------ static files ------- serving configuration #

if env == 'PROD' or env == 'PENTEST':
    # nginx will serve static files
    # TODO: staging should work this
    # way too
    app.static_folder = None
