sqlite3 biorake.sqlite3 'CREATE TABLE meta (id INTEGER PRIMARY KEY, task STRING, updated_at FLOAT);'
sqlite3 example.sqlite3 'CREATE TABLE probes (id INTEGER PRIMARY KEY, name STRING, avg FLOAT);'
sqlite3 example.sqlite3 'CREATE TABLE individuals (id INTEGER PRIMARY KEY, name STRING);'
sqlite3 example.sqlite3 'CREATE TABLE intensities (id INTEGER PRIMARY KEY, probe_id INTEGER, individual_id INTEGER, value FLOAT);'
