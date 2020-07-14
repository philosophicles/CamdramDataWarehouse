"""Turns out mysql is pretty terrible at outputting true, portable CSV files.
It's not impossible, but this seemed easier. This is a fairly quick-and-dirty
approach, based on https://stackoverflow.com/a/41840534/1837122.

Password for mysql will need to have been set via the keyring CLI first.
"""

import contextlib
import csv
import json
import os.path

import pymysql
import keyring

def read_config():
    try:
        with open('src/config.jsonc') as f:
            conf = json.load(f)
    except OSError:
        print('Config file config.jsonc cannot be opened, does it exist?')
        raise
    return conf

def output(tbl, conn, dest):
    """Write out a single table from mysql to csv"""
    # Potentially better to do in batches rather than all at once?

    with conn.cursor() as cursor:
        query = f'select * from {tbl}'
        cursor.execute(query)
        results = cursor.fetchall()

    fieldnames = results[0].keys()
    filename = f'{tbl}.csv'

    with open(os.path.join(dest, filename), 'w', newline='') as csvfile:
        csv_writer = csv.DictWriter(csvfile,
                                    fieldnames=fieldnames)
        csv_writer.writeheader()
        csv_writer.writerows(results)


if __name__ == '__main__':
    """Load config, connect to mysql, dump to CSVs"""

    config = read_config()
    user = config['mysql']['user']
    pw = keyring.get_password("mysql", user)

    connection = pymysql.connect(host=config['mysql']['host'],
                                user=user,
                                password=pw,
                                db=config['mysql']['db'],
                                cursorclass=pymysql.cursors.DictCursor)

    with contextlib.closing(connection):
        for table in config['output']['tables']:
            output(table, connection, config['output']['dir'])
