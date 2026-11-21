from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

pool = None


def init_pool(config):
    global pool
    pool = ConnectionPool(
        conninfo=config.conninfo(),
        min_size=config.DB_POOL_MIN,
        max_size=config.DB_POOL_MAX,
        kwargs={"row_factory": dict_row}, 
        open=False,
    )
    
    pool.open(wait=False)


def get_connection(timeout=5):
    return pool.connection(timeout=timeout)