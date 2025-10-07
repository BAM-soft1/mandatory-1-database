USE pet_shelter;

-- Clear existing data (in correct order due to foreign keys)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE FosterCare;
TRUNCATE TABLE Adoption;
TRUNCATE TABLE AdoptionApplication;
TRUNCATE TABLE Vaccination;
TRUNCATE TABLE VaccinationType;
TRUNCATE TABLE MedicalRecord;
TRUNCATE TABLE Animal;
TRUNCATE TABLE Veterinarian;
TRUNCATE TABLE Breed;
TRUNCATE TABLE Species;
TRUNCATE TABLE User;
SET FOREIGN_KEY_CHECKS = 1;

-- Insert Users
INSERT INTO User (email, password, first_name, last_name, phone, role, is_active) VALUES
('admin@shelter.com', '123123', 'John', 'Admin', '555-0001', 'admin', TRUE),
('dr.smith@shelter.com', '123123', 'Sarah', 'Smith', '555-0002', 'veterinarian', TRUE),
('staff@shelter.com', '123123', 'Mike', 'Johnson', '555-0003', 'staff', TRUE),
('alice@email.com', '123123', 'Alice', 'Brown', '555-0004', 'adopter', TRUE),
('bob@email.com', '123123', 'Bob', 'Wilson', '555-0005', 'adopter', TRUE),
('carol@email.com', '123123', 'Carol', 'Davis', '555-0006', 'foster', TRUE);

-- Insert Species
INSERT INTO Species (name) VALUES
('Dog'),
('Cat'),
('Rabbit');

-- Insert Breeds
INSERT INTO Breed (species_id, name) VALUES
-- Dogs
(1, 'Labrador Retriever'),
(1, 'German Shepherd'),
(1, 'Golden Retriever'),
(1, 'Bulldog'),
(1, 'Mixed Breed'),
-- Cats
(2, 'Persian'),
(2, 'Siamese'),
(2, 'Maine Coon'),
(2, 'Domestic Shorthair'),
-- Rabbits
(3, 'Holland Lop'),
(3, 'Flemish Giant');

-- Insert Animals
INSERT INTO Animal (name, species_id, breed_id, birth_date, sex, intake_date, status, price, is_active) VALUES
('Buddy', 1, 1, '2020-03-15', 'male', '2023-06-01', 'available', 150, TRUE),
('Luna', 2, 7, '2021-08-20', 'female', '2023-07-15', 'available', 100, TRUE),
('Max', 1, 2, '2019-11-10', 'male', '2023-05-20', 'adopted', 175, TRUE),
('Bella', 2, 9, '2022-01-05', 'female', '2023-08-01', 'fostered', 75, TRUE),
('Charlie', 1, 5, '2023-02-14', 'male', '2023-09-10', 'available', 200, TRUE),
('Daisy', 3, 10, '2022-06-30', 'female', '2023-09-01', 'available', 50, TRUE);

-- Insert Veterinarian
INSERT INTO Veterinarian (user_id, license_number, clinic_name, is_active) VALUES
(2, 'VET-12345', 'Shelter Veterinary Clinic', TRUE),
(NULL, 'VET-67890', 'City Animal Hospital', TRUE);

-- Insert Medical Records
INSERT INTO MedicalRecord (animal_id, vet_id, record_date, diagnosis, treatment, cost) VALUES
(1, 1, '2023-06-02', 'Routine checkup', 'General examination, healthy', 50.00),
(2, 1, '2023-07-16', 'Upper respiratory infection', 'Antibiotics prescribed', 75.00),
(3, 2, '2023-05-21', 'Dental cleaning', 'Professional teeth cleaning', 150.00),
(4, 1, '2023-08-02', 'Spay surgery', 'Ovariohysterectomy performed', 200.00),
(5, 1, '2023-09-11', 'Vaccination and checkup', 'Healthy puppy, all vaccines administered', 100.00);

-- Insert Vaccine Types
INSERT INTO VaccinationType (vaccine_name, description, duration_months, required_for_adoption) VALUES
('Rabies', 'Rabies virus vaccination - legally required in most jurisdictions', 12, TRUE),
('DHPP', 'Distemper, Hepatitis, Parvovirus, Parainfluenza combination vaccine for dogs', 12, TRUE),
('FVRCP', 'Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia combination vaccine for cats', 12, TRUE),
('Bordetella', 'Kennel cough vaccine for dogs', 6, FALSE),
('Leptospirosis', 'Bacterial disease vaccine for dogs', 12, FALSE),
('FeLV', 'Feline Leukemia Virus vaccine for cats', 12, FALSE);

-- Link vaccines to species in the junction table
INSERT INTO VaccineTypeSpecies (vaccine_type_id, species_id) VALUES
-- Rabies for all species
(1, 1),  -- Dogs
(1, 2),  -- Cats  
(1, 3),  -- Rabbits
-- DHPP for dogs only
(2, 1),  -- Dogs
-- FVRCP for cats only
(3, 2),  -- Cats
-- Optional vaccines
(4, 1),  -- Bordetella for dogs
(5, 1),  -- Leptospirosis for dogs
(6, 2);  -- FeLV for cats

-- Insert Vaccinations (now using vaccine_type_id instead of vaccine_name)
INSERT INTO Vaccination (animal_id, vet_id, vaccine_type_id, date_administered, next_due_date) VALUES
(1, 1, 1, '2023-06-02', '2024-06-02'),  -- Buddy - Rabies
(1, 1, 2, '2023-06-02', '2024-06-02'),  -- Buddy - DHPP
(2, 1, 3, '2023-07-16', '2024-07-16'),  -- Luna - FVRCP
(2, 1, 1, '2023-07-16', '2024-07-16'),  -- Luna - Rabies
(3, 2, 1, '2023-05-21', '2024-05-21'),  -- Max - Rabies
(5, 1, 1, '2023-09-11', '2024-09-11'),  -- Charlie - Rabies
(5, 1, 2, '2023-09-11', '2024-09-11');  -- Charlie - DHPP

-- Insert Adoption Applications
INSERT INTO AdoptionApplication (user_id, animal_id, application_date, status, reviewed_by_user_id, is_active) VALUES
(4, 3, '2023-06-01', 'approved', 3, TRUE),
(5, 1, '2023-09-15', 'pending', NULL, TRUE),
(4, 2, '2023-09-20', 'pending', NULL, TRUE);

-- Insert Adoptions
INSERT INTO Adoption (application_id, animal_id, adopter_user_id, adoption_date, is_active) VALUES
(1, 3, 4, '2023-06-10', TRUE);

-- Insert Foster Care
INSERT INTO FosterCare (animal_id, foster_parent_user_id, start_date, end_date, is_active) VALUES
(4, 6, '2023-08-05', NULL, TRUE);

-- Display summary
SELECT 'Data inserted successfully!' AS Status;
SELECT COUNT(*) AS total_users FROM User;
SELECT COUNT(*) AS total_animals FROM Animal;
SELECT COUNT(*) AS total_species FROM Species;
SELECT COUNT(*) AS total_breeds FROM Breed;
SELECT COUNT(*) AS total_vaccine_types FROM VaccinationType;
SELECT COUNT(*) AS total_vaccinations FROM Vaccination;