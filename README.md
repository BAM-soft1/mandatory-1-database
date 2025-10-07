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

## Indexes, Triggers, Events, Stored Procedures & Functions

1. Enable advanced features (run as root):

```bash
docker exec -i pet_shelter_db mysql -u root -prootpassword -e "SET GLOBAL log_bin_trust_function_creators = 1; SET GLOBAL event_scheduler = ON;"
```

2. Run the features script:

```bash
docker exec -i pet_shelter_db mysql -u shelter_user -pshelterpass pet_shelter < ./database/features.sql
```

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

### Test the different stored objects:

#### Stored Procedures

1. **Add a new animal:**

```sql
CALL AddNewAnimal('Rocky', 'Dog', 'Husky', '2023-01-15', 'male', 150, @new_id);
SELECT @new_id;
```

2. **Get medical history:**

```sql
CALL GetAnimalMedicalHistory(1);
```

3. **Complete an adoption:**

```sql
SELECT * FROM PendingApplicationsView;
CALL CompleteAdoption(2, CURDATE());

-- Verify the adoption was created
SELECT * FROM Adoption WHERE application_id = 2;

-- Verify the animal status was updated
SELECT * FROM Animal WHERE animal_id = 1;
```

#### Stored functions

1. **Get animal age:**

```sql
SELECT name, GetAnimalAge(birth_date) AS age FROM Animal;
```

2. **Check vaccination status:**

```sql
SELECT name, HasRequiredVaccinations(animal_id) AS ready_for_adoption FROM Animal;
```

3. **Get total adoption cost:**

```sql
SELECT name, price AS base_price, GetTotalAdoptionCost(animal_id) AS total_cost_with_medical FROM Animal;
```

#### Views

1. **See all available animals:**

```sql
SELECT * FROM AvailableAnimalsView;
```

2. **See adoption history:**

```sql
SELECT * FROM AdoptionHistoryView;
```

3. **Check vaccination status:**

```sql
SELECT * FROM VaccinationStatusView;
```

4. **View pending applications:**

```sql
SELECT * FROM PendingApplicationsView;
```

#### Triggers

1. **Test automatic status update when adoption is created:**

```sql
-- Check current status
SELECT animal_id, name, status FROM Animal WHERE animal_id = 2;

-- Create an adoption
INSERT INTO Adoption (application_id, animal_id, adopter_user_id, adoption_date)
VALUES (3, 2, 5, CURDATE());

-- Check animal status changed to adopted
SELECT animal_id, name, status FROM Animal WHERE animal_id = 2;

-- Check application status changed to approved
SELECT application_id, status FROM AdoptionApplication WHERE application_id = 3;
```

#### Events

Events run automatically on schedule. To verify they exist:

```sql
SHOW EVENTS;
```

## Clean Up Test Data

If you want to reset the database:

```bash
docker-compose down -v
docker-compose up -d
# Wait 10 seconds
docker exec -i pet_shelter_db mysql -u shelter_user -pshelterpass pet_shelter < ./database/testdata.sql
docker exec -i pet_shelter_db mysql -u root -prootpassword -e "SET GLOBAL log_bin_trust_function_creators = 1; SET GLOBAL event_scheduler = ON;"
docker exec -i pet_shelter_db mysql -u shelter_user -pshelterpass pet_shelter < ./database/features.sql
```
