
-- CREATE DATABASE IF NOT EXISTS note_db;

DROP TABLE IF EXISTS note;

DROP TABLE IF EXISTS tag;

CREATE TABLE note (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    title       varchar(64),
    text        text
);

CREATE TABLE tag (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        varchar(64),
    note_id     int
);
