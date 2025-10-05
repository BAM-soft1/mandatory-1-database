USE pet_shelter;

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Procedure 1: Complete an adoption
DROP PROCEDURE IF EXISTS CompleteAdoption;
DELIMITER //
CREATE PROCEDURE CompleteAdoption(
    IN p_application_id INT,
    IN p_adoption_date DATE
)
BEGIN
    DECLARE v_animal_id INT;
    DECLARE v_adopter_id INT;
    
    -- Get animal and adopter info from application
    SELECT animal_id, user_id INTO v_animal_id, v_adopter_id
    FROM AdoptionApplication
    WHERE application_id = p_application_id;
    
    -- Check if application exists and is approved
    IF v_animal_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Application not found';
    END IF;
    
    -- Create adoption record
    INSERT INTO Adoption (application_id, animal_id, adopter_user_id, adoption_date)
    VALUES (p_application_id, v_animal_id, v_adopter_id, p_adoption_date);
    
    -- Update animal status
    UPDATE Animal SET status = 'adopted' WHERE animal_id = v_animal_id;
    
    -- Update application status
    UPDATE AdoptionApplication SET status = 'approved' WHERE application_id = p_application_id;
END //
DELIMITER ;

-- Procedure 2: Add a new animal with basic info
DROP PROCEDURE IF EXISTS AddNewAnimal;
DELIMITER //
CREATE PROCEDURE AddNewAnimal(
    IN p_name VARCHAR(100),
    IN p_species_name VARCHAR(50),
    IN p_breed_name VARCHAR(100),
    IN p_birth_date DATE,
    IN p_sex ENUM('male', 'female', 'unknown'),
    IN p_price INT,
    OUT p_animal_id INT
)
BEGIN
    DECLARE v_species_id INT;
    DECLARE v_breed_id INT;
    
    -- Get or create species
    SELECT species_id INTO v_species_id FROM Species WHERE name = p_species_name;
    IF v_species_id IS NULL THEN
        INSERT INTO Species (name) VALUES (p_species_name);
        SET v_species_id = LAST_INSERT_ID();
    END IF;
    
    -- Get or create breed
    SELECT breed_id INTO v_breed_id FROM Breed WHERE name = p_breed_name AND species_id = v_species_id;
    IF v_breed_id IS NULL THEN
        INSERT INTO Breed (species_id, name) VALUES (v_species_id, p_breed_name);
        SET v_breed_id = LAST_INSERT_ID();
    END IF;
    
    -- Insert animal
    INSERT INTO Animal (name, species_id, breed_id, birth_date, sex, intake_date, price)
    VALUES (p_name, v_species_id, v_breed_id, p_birth_date, p_sex, CURDATE(), p_price);
    
    SET p_animal_id = LAST_INSERT_ID();
END //
DELIMITER ;

-- Procedure 3: Get animal medical history
DROP PROCEDURE IF EXISTS GetAnimalMedicalHistory;
DELIMITER //
CREATE PROCEDURE GetAnimalMedicalHistory(
    IN p_animal_id INT
)
BEGIN
    SELECT 
        mr.record_date,
        mr.diagnosis,
        mr.treatment,
        mr.cost,
        CONCAT(u.first_name, ' ', u.last_name) AS veterinarian
    FROM MedicalRecord mr
    JOIN Veterinarian v ON mr.vet_id = v.vet_id
    LEFT JOIN User u ON v.user_id = u.user_id
    WHERE mr.animal_id = p_animal_id
    ORDER BY mr.record_date DESC;
END //
DELIMITER ;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function 1: Calculate animal age in years
DROP FUNCTION IF EXISTS GetAnimalAge;
DELIMITER //
CREATE FUNCTION GetAnimalAge(p_birth_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_birth_date, CURDATE());
END //
DELIMITER ;

-- Function 2: Check if animal has all required vaccinations
DROP FUNCTION IF EXISTS HasRequiredVaccinations;
DELIMITER //
CREATE FUNCTION HasRequiredVaccinations(p_animal_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_required_count INT;
    DECLARE v_actual_count INT;
    
    -- Count required vaccines
    SELECT COUNT(*) INTO v_required_count
    FROM VaccinationType
    WHERE required_for_adoption = TRUE;
    
    -- Count how many required vaccines this animal has (that are still valid)
    SELECT COUNT(DISTINCT vt.vaccine_type_id) INTO v_actual_count
    FROM Vaccination v
    JOIN VaccinationType vt ON v.vaccine_type_id = vt.vaccine_type_id
    WHERE v.animal_id = p_animal_id
    AND vt.required_for_adoption = TRUE
    AND v.next_due_date >= CURDATE();
    
    RETURN v_actual_count >= v_required_count;
END //
DELIMITER ;

-- Function 3: Get total adoption fee (animal price + medical costs)
DROP FUNCTION IF EXISTS GetTotalAdoptionCost;
DELIMITER //
CREATE FUNCTION GetTotalAdoptionCost(p_animal_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_animal_price DECIMAL(10,2);
    DECLARE v_medical_costs DECIMAL(10,2);
    
    SELECT price INTO v_animal_price FROM Animal WHERE animal_id = p_animal_id;
    
    SELECT IFNULL(SUM(cost), 0) INTO v_medical_costs
    FROM MedicalRecord
    WHERE animal_id = p_animal_id;
    
    RETURN v_animal_price + v_medical_costs;
END //
DELIMITER ;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger 1: Automatically update animal status when adopted
DROP TRIGGER IF EXISTS after_adoption_insert;
DELIMITER //
CREATE TRIGGER after_adoption_insert
AFTER INSERT ON Adoption
FOR EACH ROW
BEGIN
    UPDATE Animal 
    SET status = 'adopted' 
    WHERE animal_id = NEW.animal_id;
END //
DELIMITER ;

-- Trigger 2: Automatically set application status to 'approved' when adoption is completed
DROP TRIGGER IF EXISTS after_adoption_application_update;
DELIMITER //
CREATE TRIGGER after_adoption_application_update
AFTER INSERT ON Adoption
FOR EACH ROW
BEGIN
    UPDATE AdoptionApplication 
    SET status = 'approved' 
    WHERE application_id = NEW.application_id;
END //
DELIMITER ;

-- Trigger 3: Update animal status when foster care starts
DROP TRIGGER IF EXISTS after_foster_insert;
DELIMITER //
CREATE TRIGGER after_foster_insert
AFTER INSERT ON FosterCare
FOR EACH ROW
BEGIN
    IF NEW.is_active = TRUE THEN
        UPDATE Animal 
        SET status = 'fostered' 
        WHERE animal_id = NEW.animal_id;
    END IF;
END //
DELIMITER ;

-- Trigger 4: Update animal status when foster care ends
DROP TRIGGER IF EXISTS after_foster_update;
DELIMITER //
CREATE TRIGGER after_foster_update
AFTER UPDATE ON FosterCare
FOR EACH ROW
BEGIN
    IF OLD.is_active = TRUE AND NEW.is_active = FALSE THEN
        UPDATE Animal 
        SET status = 'available' 
        WHERE animal_id = NEW.animal_id;
    END IF;
END //
DELIMITER ;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View 1: Available animals with full details
CREATE OR REPLACE VIEW AvailableAnimalsView AS
SELECT 
    a.animal_id,
    a.name,
    s.name AS species,
    b.name AS breed,
    a.birth_date,
    GetAnimalAge(a.birth_date) AS age_years,
    a.sex,
    a.intake_date,
    a.price,
    HasRequiredVaccinations(a.animal_id) AS has_required_vaccines,
    CASE 
        WHEN HasRequiredVaccinations(a.animal_id) THEN 'Ready for adoption'
        ELSE 'Needs vaccinations'
    END AS adoption_status
FROM Animal a
JOIN Species s ON a.species_id = s.species_id
LEFT JOIN Breed b ON a.breed_id = b.breed_id
WHERE a.status = 'available' AND a.is_active = TRUE;

-- View 2: Adoption history with adopter details
CREATE OR REPLACE VIEW AdoptionHistoryView AS
SELECT 
    a.adoption_id,
    an.name AS animal_name,
    s.name AS species,
    b.name AS breed,
    CONCAT(u.first_name, ' ', u.last_name) AS adopter_name,
    u.email AS adopter_email,
    u.phone AS adopter_phone,
    a.adoption_date,
    DATEDIFF(CURDATE(), a.adoption_date) AS days_since_adoption
FROM Adoption a
JOIN Animal an ON a.animal_id = an.animal_id
JOIN Species s ON an.species_id = s.species_id
LEFT JOIN Breed b ON an.breed_id = b.breed_id
JOIN User u ON a.adopter_user_id = u.user_id
WHERE a.is_active = TRUE;

-- View 3: Vaccination status for all animals
CREATE OR REPLACE VIEW VaccinationStatusView AS
SELECT 
    a.animal_id,
    a.name AS animal_name,
    vt.vaccine_name,
    v.date_administered,
    v.next_due_date,
    CASE 
        WHEN v.next_due_date < CURDATE() THEN 'Overdue'
        WHEN v.next_due_date < DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 'Due Soon'
        ELSE 'Up to Date'
    END AS status,
    DATEDIFF(v.next_due_date, CURDATE()) AS days_until_due
FROM Animal a
LEFT JOIN Vaccination v ON a.animal_id = v.animal_id
LEFT JOIN VaccinationType vt ON v.vaccine_type_id = vt.vaccine_type_id
WHERE a.is_active = TRUE
ORDER BY a.animal_id, v.next_due_date;

-- View 4: Pending adoption applications
CREATE OR REPLACE VIEW PendingApplicationsView AS
SELECT 
    aa.application_id,
    an.name AS animal_name,
    s.name AS species,
    CONCAT(u.first_name, ' ', u.last_name) AS applicant_name,
    u.email AS applicant_email,
    u.phone AS applicant_phone,
    aa.application_date,
    DATEDIFF(CURDATE(), aa.application_date) AS days_pending
FROM AdoptionApplication aa
JOIN Animal an ON aa.animal_id = an.animal_id
JOIN Species s ON an.species_id = s.species_id
JOIN User u ON aa.user_id = u.user_id
WHERE aa.status = 'pending' AND aa.is_active = TRUE
ORDER BY aa.application_date;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index 1: Speed up user login queries
CREATE INDEX idx_user_email ON User(email);

-- Index 2: Speed up animal searches by name
CREATE INDEX idx_animal_name ON Animal(name);

-- Index 3: Speed up animal filtering by status
CREATE INDEX idx_animal_status ON Animal(status);

-- Index 4: Speed up queries for animals by species
CREATE INDEX idx_animal_species ON Animal(species_id);

-- Index 5: Composite index for finding available animals of a specific species
CREATE INDEX idx_animal_species_status ON Animal(species_id, status);

-- Index 6: Speed up vaccination lookups by animal
CREATE INDEX idx_vaccination_animal ON Vaccination(animal_id);

-- Index 7: Speed up vaccination due date checks
CREATE INDEX idx_vaccination_due_date ON Vaccination(next_due_date);

-- Index 8: Speed up medical record lookups
CREATE INDEX idx_medical_animal ON MedicalRecord(animal_id);

-- Index 9: Speed up application queries by user
CREATE INDEX idx_application_user ON AdoptionApplication(user_id);

-- Index 10: Speed up application queries by status
CREATE INDEX idx_application_status ON AdoptionApplication(status);

-- ============================================================================
-- EVENTS
-- ============================================================================

-- Enable the event scheduler (you may need to run this separately with admin privileges)
-- SET GLOBAL event_scheduler = ON;

-- Event 1: Daily check for overdue vaccinations and log them
DROP EVENT IF EXISTS daily_vaccination_check;
DELIMITER //
CREATE EVENT daily_vaccination_check
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_overdue_vaccines AS
    SELECT 
        a.animal_id,
        a.name,
        vt.vaccine_name,
        v.next_due_date
    FROM Animal a
    JOIN Vaccination v ON a.animal_id = v.animal_id
    JOIN VaccinationType vt ON v.vaccine_type_id = vt.vaccine_type_id
    WHERE v.next_due_date < CURDATE()
    AND a.is_active = TRUE;
END //
DELIMITER ;

-- Event 2: Monthly cleanup of old rejected applications (older than 6 months)
DROP EVENT IF EXISTS monthly_cleanup_old_applications;
DELIMITER //
CREATE EVENT monthly_cleanup_old_applications
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_DATE + INTERVAL 1 MONTH
DO
BEGIN
    UPDATE AdoptionApplication
    SET is_active = FALSE
    WHERE status = 'rejected'
    AND application_date < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    AND is_active = TRUE;
END //
DELIMITER ;

-- Event 3: Weekly reminder for animals in foster care over 90 days
DROP EVENT IF EXISTS weekly_long_term_foster_check;
DELIMITER //
CREATE EVENT weekly_long_term_foster_check
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL 1 WEEK
DO
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_long_term_fosters AS
    SELECT 
        fc.foster_id,
        a.name AS animal_name,
        CONCAT(u.first_name, ' ', u.last_name) AS foster_parent,
        fc.start_date,
        DATEDIFF(CURDATE(), fc.start_date) AS days_in_foster
    FROM FosterCare fc
    JOIN Animal a ON fc.animal_id = a.animal_id
    JOIN User u ON fc.foster_parent_user_id = u.user_id
    WHERE fc.is_active = TRUE
    AND fc.end_date IS NULL
    AND DATEDIFF(CURDATE(), fc.start_date) > 90;
END //
DELIMITER ;