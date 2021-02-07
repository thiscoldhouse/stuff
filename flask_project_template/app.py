import sys
import os
PROJECT_ROOT = os.path.dirname(os.path.realpath(__file__))
sys.path.append(PROJECT_ROOT)

from project import app, logger, CONFIG, db
from routes import *

def run_migrations_on_dev_server_restart():
    logger.info('Running migrations')
    current = None
    from sqlalchemy import create_engine
    with create_engine(
        f"postgresql://{CONFIG['DB_USER']}:{CONFIG['DB_PW']}"
        f"@{CONFIG['DB_HOST']}:{CONFIG['DB_PORT']}/{CONFIG['DB_NAME']}"
    ).connect() as connection:
        # If the database was just created from scratch, there will be no
        # alembic_version table, and current will be set to None.
        with connection.begin():
            current = attempt_to_get_alembic_version(connection)

    if current:
        logger.info(f'The current revision is {current}')
    else:
        logger.info('Could not find a current revision in the DB')

    # Get the Flask-Migrate config:
    config = Migrate(
        app,
        db,
        directory=os.path.join(PROJECT_ROOT, 'migrations')
    ).get_config()

    # We want to run any migrations that haven't been run yet. First, get
    # all the revision identifiers (as strings) and store them.

    revisions = []
    script_directory = ScriptDirectory.from_config(config)
    for revision_script in script_directory.walk_revisions(head='head'):
        revisions.append(revision_script.revision)

    # walk_revisions starts from the head and goes backwards. We want to
    # migrate up from scratch, so we need to reverse the order.
    revisions.reverse()

    # False if there is a current revision (in which case, we don't want to
    # start migrating yet), True if there is none and the database was just
    # created.
    migrating = False if current else True

    with app.app_context():
        for revision in revisions:
            if migrating:
                logger.info(f'Upgrading to {revision}')
                command.upgrade(config, revision)

            # One we reach the current revision, we want to upgrade, one step
            # at a time, for each subsequent revision. If we don't do this,
            # queries in migrations (but not DDL) will fail.
            if current and current == revision:
                migrating = True

    logger.info('Migrations finished')


if __name__ == '__main__':
    # uncomment to automatically run migrations when the dev server restarts:
    # run_migrations_on_dev_server_restart()
    logger.info('Running dev server')
    app.run(host='0.0.0.0', port=8000, debug=True)
