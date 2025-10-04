# Pet Shelter Database - Installation Guide

## Installation

1. Create a `.env` file:

```env
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_USER=shelter_user
MYSQL_PASSWORD=shelterpass
```

2. Start the database:

```bash
docker-compose up -d
```

3. Wait 10 seconds, then load test data (only needed first time):

```bash
docker exec -i pet_shelter_db mysql -u shelter_user -pshelterpass pet_shelter < ./database/testdata.sql
```

- If you get the following error: ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)
  - Then wait five seconds more before running the script.

## Connect to Database

**DataGrip / MySQL Workbench:**

- Host: `localhost`
- Port: `3307`
- User: `shelter_user`
- Password: `shelterpass`
- Database: `pet_shelter`

**Command line:**

```bash
mysql -h 127.0.0.1 -P 3307 -u shelter_user -pshelterpass pet_shelter
```

## Verify Installation

```sql
SELECT COUNT(*) FROM Animal;  -- Should return: 6
```
