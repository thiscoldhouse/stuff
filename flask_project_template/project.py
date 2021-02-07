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

# ------------ CONFIG ---------- #
CONFIG = {
    'DB_HOST': 'bis-db',
    'DB_PORT': '5432',
    'DB_USER': 'grc',
    'DB_PW': 'bisrules',
    'DB_NAME': 'bis',
}

# -------- setup flask app ------- #
from flask import Flask
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

# ------------- DB ------------- #
DB_CONN = 'postgresql://{user}:{password}@{host}:{port}/{dbname}'
DB_CONN = DB_CONN.format(
    user=CONFIG['DB_USER'],
    password=CONFIG['DB_PW'],
    host=CONFIG['DB_HOST'],
    port=CONFIG['DB_PORT'],
    dbname=CONFIG['DB_NAME']
)
app.config['SQLALCHEMY_DATABASE_URI'] = DB_CONN
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app, session_options={ 'autoflush': False })



# ------ static files ------- serving configuration #

if env == 'PROD' or env == 'PENTEST':
    # nginx will serve static files
    # TODO: staging should work this
    # way too
    app.static_folder = None


# ------------ logging ------------- #
import logging
import logging.handlers
import traceback


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

if app.debug:
    # We have our own request logging, but werkzeug's logger needs to be set to
    # INFO if we are debugging so we can get the debugger PINs in the console.
    logging.getLogger('werkzeug').setLevel(logging.INFO)

# Uncomment this line if you want to read every SQL query that gets made:
#logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

class CustomFormatter(logging.Formatter):
    custom_format = '%(asctime)s %(process)d [%(levelname)s] %(name)s - %(message)s'
    custom_root_format = '%(asctime)s %(process)d [%(levelname)s] %(message)s'

    def __init__(self):
        self._custom_root_style = logging.PercentStyle(self.custom_root_format)
        super().__init__(self.custom_format)

    def formatMessage(self, record):
        if record.name == 'root':
            return self._custom_root_style.format(record)
        return self._style.format(record)

formatter = CustomFormatter()

# This does not handle any file rotation
file_handler = logging.FileHandler('/var/log/bis-edit/bis-edit.log')
stream_handler = logging.StreamHandler()

file_handler.setLevel(logging.DEBUG)
stream_handler.setLevel(logging.DEBUG)

stream_handler.setFormatter(formatter)
file_handler.setFormatter(formatter)

logger.addHandler(file_handler)
logger.addHandler(stream_handler)
