from exercise_mgr.database.create_tables import create_all_tables
from exercise_mgr.database.sqlite_wrapper import create_connection
from exercise_mgr.Settings import Settings


def main(database):
    conn = create_connection(database)
    with conn:
        create_all_tables(conn)


if __name__ == '__main__':
    main(Settings.database)
