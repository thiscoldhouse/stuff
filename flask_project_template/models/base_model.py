from project import db

import uuid
from sqlalchemy import func

class BaseModel(db.Model):
    __abstract__ = True

    # If we ever use flask-admin, this tells it to display the primary key in the list view.
    # If not it just does nothing
    column_display_pk = True

    # a UUID used for external API calls. I find autoincrementing ids very useful
    # as a human, but for external integrations I think it's better to use a uuid
    # to avoid gueassability and leaking unnecessary information about our system
    api_key = db.Column(db.Text, default=uuid.uuid4, nullable=False, unique=True)
    created_date = db.Column(
        db.DateTime,
        server_default=func.now(),
        nullable=False
    )

    def __repr__(self):
        if hasattr(self, 'name'):
            return "<{0} {1} '{2}'>".format(
                self.__class__.__name__,
                self.id,
                self.name
            )
        return super().__repr__()
