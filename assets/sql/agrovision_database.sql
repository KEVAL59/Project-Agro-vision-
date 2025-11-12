-- Agro Vision Database Script

-- Step 1: Create Database
DROP DATABASE IF EXISTS AgroVision;
CREATE DATABASE AgroVision;
USE AgroVision;

-- Step 2: Create Tables
CREATE TABLE Farmers (
    farmer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE,
    location VARCHAR(100)
);

CREATE TABLE Crops (
    crop_id INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id INT,
    crop_name VARCHAR(100),
    season VARCHAR(50),
    FOREIGN KEY (farmer_id) REFERENCES Farmers(farmer_id)
);

CREATE TABLE Weather (
    weather_id INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(100),
    record_date DATE,
    temperature FLOAT,
    humidity FLOAT,
    rainfall FLOAT
);

CREATE TABLE MarketPrices (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    crop_id INT,
    market_location VARCHAR(100),
    price DECIMAL(10,2),
    record_date DATE,
    FOREIGN KEY (crop_id) REFERENCES Crops(crop_id)
);

CREATE TABLE CropHealth (
    health_id INT AUTO_INCREMENT PRIMARY KEY,
    crop_id INT,
    diagnosis VARCHAR(255),
    report_date DATE,
    FOREIGN KEY (crop_id) REFERENCES Crops(crop_id)
);

-- Step 3: Insert Sample Data
INSERT INTO Farmers (name, phone, location) VALUES 
('Ramesh Patel', '9876543210', 'Ahmedabad'),
('Sita Desai', '9123456780', 'Vadodara');

INSERT INTO Crops (farmer_id, crop_name, season) VALUES 
(1, 'Wheat', 'Rabi'),
(1, 'Cotton', 'Kharif'),
(2, 'Rice', 'Kharif');

INSERT INTO Weather (location, record_date, temperature, humidity, rainfall) VALUES
('Ahmedabad', '2025-08-23', 32.5, 65.0, 12.4),
('Vadodara', '2025-08-23', 30.0, 70.0, 15.2);

INSERT INTO MarketPrices (crop_id, market_location, price, record_date) VALUES
(1, 'Ahmedabad Mandi', 2500.00, '2025-08-23'),
(2, 'Ahmedabad Mandi', 5500.00, '2025-08-23'),
(3, 'Vadodara Mandi', 3200.00, '2025-08-23');

INSERT INTO CropHealth (crop_id, diagnosis, report_date) VALUES
(1, 'Healthy growth stage', '2025-08-22'),
(2, 'Pest infection detected', '2025-08-23'),
(3, 'Nutrient deficiency signs', '2025-08-21');

SHOW databases;
USE AgroVision;
SHOW tableS;
SELECT * FROM Farmers;
SELECT * FROM crops;
SELECT * FROM marketprices;
SELECT * FROM weather;
SELECT * FROM crophealth;