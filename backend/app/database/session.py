from sqlalchemy import create_engine, event
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

db_url = settings.DATABASE_URL
if db_url.startswith("postgresql://"):
    db_url = db_url.replace("postgresql://", "postgresql+psycopg2://", 1)

engine_kwargs = {"pool_pre_ping": True}
connect_args = {}

if db_url.startswith("sqlite"):
    connect_args["check_same_thread"] = False
else:
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20

engine = create_engine(
    db_url,
    connect_args=connect_args,
    **engine_kwargs,
)

if not db_url.startswith("sqlite"):
    @event.listens_for(engine, "connect")
    def set_search_path(dbapi_connection, connection_record):
        try:
            cursor = dbapi_connection.cursor()
            cursor.execute("CREATE SCHEMA IF NOT EXISTS expenseflow;")
            cursor.execute("SET search_path TO expenseflow, public;")
            cursor.close()
        except Exception:
            pass

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependency for yielding database session with automatic cleanup."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
