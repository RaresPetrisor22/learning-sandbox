-- Setup

CREATE TABLE teams (
    id INT PRIMARY KEY,
    team VARCHAR (100) NOT NULL,
    city VARCHAR (100) NOT NULL
);

CREATE TABLE players (
    id INT PRIMARY KEY,
    team_id INT REFERENCES teams (id),
    player VARCHAR (100) NOT NULL,
    role VARCHAR (100) NOT NULL
);

INSERT INTO teams (id, team, city)
VALUES
    (1, 'Lions', 'Rome'),
    (2, 'Owls', 'Oslo'),
    (3, 'Bears', 'Bern'),
    (4, 'Sharks', 'Lima');

INSERT INTO players (id, team_id, player, role)
VALUES
    (1, 1, 'Ava', 'Guard'),
    (2, 1, 'Noah', 'Wing'),
    (3, 2, 'Emma', 'Back'),
    (4, NULL, 'Liam', 'Guard'),
    (5, NULL, 'Mia', 'Wing');

-- Inner Join

SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role 
FROM
    teams
JOIN players
    ON teams.id = players.team_id;

-- Left Join

SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role
FROM
    teams
LEFT JOIN players
    ON teams.id = players.team_id

-- rows from the left table that do not have matching rows in the right table
SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role
FROM
    teams
LEFT JOIN players
    ON teams.id = players.team_id
WHERE players.id IS NULL;

-- right join
SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role
FROM
    teams
RIGHT JOIN players ON teams.id = players.team_id;

SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role
FROM
    teams
RIGHT JOIN players
   ON teams.id = players.team_id
WHERE teams.id IS NULL;

-- full join
SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role
FROM
    teams
FULL OUTER JOIN players
    ON teams.id = players.team_id;

SELECT
    teams.id AS team_id,
    team,
    city,
    players.id AS player_id,
    player,
    role
FROM
    teams
FULL OUTER JOIN players
    ON teams.id = players.team_id
WHERE teams.id IS NULL OR players.id IS NULL;