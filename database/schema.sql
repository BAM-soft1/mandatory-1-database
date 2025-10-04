DROP DATABASE IF EXISTS pet_shelter;
CREATE DATABASE pet_shelter CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_shelter;

-- Users table
CREATE TABLE User (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('admin', 'staff', 'veterinarian', 'adopter', 'foster') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Species table
CREATE TABLE Species (
    species_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Breed table
CREATE TABLE Breed (
    breed_id INT PRIMARY KEY AUTO_INCREMENT,
    species_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (species_id) REFERENCES Species(species_id) ON DELETE RESTRICT,
    UNIQUE KEY unique_breed_per_species (species_id, name)
);

-- Animal table
CREATE TABLE Animal (
    animal_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    species_id INT NOT NULL,
    breed_id INT,
    birth_date DATE,
    sex ENUM('male', 'female', 'unknown') NOT NULL,
    intake_date DATE NOT NULL,
    status ENUM('available', 'adopted', 'fostered', 'deceased') DEFAULT 'available',
    price INT NOT NULL CHECK (price >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (species_id) REFERENCES Species(species_id) ON DELETE RESTRICT,
    FOREIGN KEY (breed_id) REFERENCES Breed(breed_id) ON DELETE SET NULL
);

-- Veterinarian table
CREATE TABLE Veterinarian (
    vet_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    clinic_name VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE SET NULL
);

-- Medical Record table
CREATE TABLE MedicalRecord (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    animal_id INT NOT NULL,
    vet_id INT NOT NULL,
    record_date DATE NOT NULL,
    diagnosis TEXT,
    treatment TEXT,
    cost DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (animal_id) REFERENCES Animal(animal_id) ON DELETE RESTRICT,
    FOREIGN KEY (vet_id) REFERENCES Veterinarian(vet_id) ON DELETE RESTRICT
);

-- Vaccine Type table
CREATE TABLE VaccinationType (
    vaccine_type_id INT PRIMARY KEY AUTO_INCREMENT,
    vaccine_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    duration_months INT,
    required_for_adoption BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vaccination table
CREATE TABLE Vaccination (
    vaccination_id INT PRIMARY KEY AUTO_INCREMENT,
    animal_id INT NOT NULL,
    vet_id INT NOT NULL,
    vaccine_type_id INT NOT NULL,
    date_administered DATE NOT NULL,
    next_due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (animal_id) REFERENCES Animal(animal_id) ON DELETE RESTRICT,
    FOREIGN KEY (vet_id) REFERENCES Veterinarian(vet_id) ON DELETE RESTRICT,
    FOREIGN KEY (vaccine_type_id) REFERENCES VaccinationType(vaccine_type_id) ON DELETE RESTRICT
);

-- Adoption Application table
CREATE TABLE AdoptionApplication (
    application_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    animal_id INT NOT NULL,
    application_date DATE NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    reviewed_by_user_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (animal_id) REFERENCES Animal(animal_id) ON DELETE RESTRICT,
    FOREIGN KEY (reviewed_by_user_id) REFERENCES User(user_id) ON DELETE SET NULL
);

-- Adoption table
CREATE TABLE Adoption (
    adoption_id INT PRIMARY KEY AUTO_INCREMENT,
    application_id INT NOT NULL UNIQUE,
    animal_id INT NOT NULL,
    adopter_user_id INT NOT NULL,
    adoption_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES AdoptionApplication(application_id) ON DELETE RESTRICT,
    FOREIGN KEY (animal_id) REFERENCES Animal(animal_id) ON DELETE RESTRICT,
    FOREIGN KEY (adopter_user_id) REFERENCES User(user_id) ON DELETE RESTRICT
);

-- Foster Care table
CREATE TABLE FosterCare (
    foster_id INT PRIMARY KEY AUTO_INCREMENT,
    animal_id INT NOT NULL,
    foster_parent_user_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (animal_id) REFERENCES Animal(animal_id) ON DELETE RESTRICT,
    FOREIGN KEY (foster_parent_user_id) REFERENCES User(user_id) ON DELETE RESTRICT
);