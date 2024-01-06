alter session set nls_language='ENGLISH';
alter session set nls_date_format='YYYY-MM-DD';

DROP TABLE Patient_Lab_Tests;
DROP TABLE Associated_With_BI;
DROP TABLE Insurance_Claim;
DROP TABLE Billing;
DROP TABLE Laboratory_Test;
DROP TABLE Appointment;
DROP TABLE Staff;
DROP TABLE Patient_Treatment;
DROP TABLE Treatment;
DROP TABLE Prescription;
DROP TABLE Patient;
DROP TABLE Medication;

CREATE TABLE Patient (
    PatientID NUMBER(10) CONSTRAINT pk_patient_id PRIMARY KEY,
    Namee VARCHAR2(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender VARCHAR2(10),
    Address VARCHAR2(100),
    ContactNumber VARCHAR2(8) UNIQUE,
    EmergencyContact VARCHAR2(15),
    InsuranceDetails VARCHAR2(100)
);

CREATE TABLE Medication (
    MedicationID NUMBER CONSTRAINT pk_medication_id PRIMARY KEY,
    Namee VARCHAR2(50) NOT NULL,
    Descriptionn VARCHAR2(200),
    SideEffects VARCHAR2(200)
);

CREATE TABLE Prescription (
    PrescriptionID NUMBER CONSTRAINT pk_prescription_id PRIMARY KEY,
    PatientID NUMBER NOT NULL,
    MedicationID NUMBER NOT NULL,
    Dosage VARCHAR2(50),
    Frequency VARCHAR2(50),
    StartDate DATE,
    EndDate DATE,
    CONSTRAINT fk_prescription_patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    CONSTRAINT fk_prescription_medication FOREIGN KEY (MedicationID) REFERENCES Medication(MedicationID),
    CONSTRAINT chk_date_available_pres CHECK (StartDate < EndDate)
);

CREATE TABLE Treatment (
    TreatmentID NUMBER CONSTRAINT pk_treatment_id PRIMARY KEY,
    Descriptionn VARCHAR2(200) NOT NULL,
    Costt NUMBER
);

CREATE TABLE Patient_Treatment (
    PatientID NUMBER NOT NULL,
    TreatmentID NUMBER NOT NULL,
    DateOfTreatment DATE NOT NULL,
    Outcome VARCHAR2(100),
    CONSTRAINT pk_patient_treatment PRIMARY KEY (PatientID, TreatmentID, DateOfTreatment),
    CONSTRAINT fk_patient_treatment_patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    CONSTRAINT fk_patient_treatment_treatment FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
);

CREATE TABLE Staff (
    StaffID NUMBER CONSTRAINT pk_staff_id PRIMARY KEY,
    Namee VARCHAR2(50) NOT NULL,
    Positionn VARCHAR2(50),
    Department VARCHAR2(50),
    ContactNumber VARCHAR2(15),
    Address VARCHAR2(100),
    Salary NUMBER,
    HireDate DATE NOT NULL,
    AvailableTimeStart DATE,
    AvailableTimeEnd DATE,
    CONSTRAINT chk_date_available_staff CHECK (AvailableTimeEnd > AvailableTimeStart AND AvailableTimeStart > HireDate)
);

CREATE TABLE Appointment (
    AppointmentID NUMBER CONSTRAINT pk_appointment_id PRIMARY KEY,
    PatientID NUMBER NOT NULL,
    DoctorID NUMBER NOT NULL,
    AppointmentDate TIMESTAMP NOT NULL,
    Purpose VARCHAR2(100),
    CONSTRAINT fk_patient_appt FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    CONSTRAINT fk_doctor_appt FOREIGN KEY (DoctorID) REFERENCES Staff(StaffID)
);

CREATE TABLE Laboratory_Test (
    TestID NUMBER CONSTRAINT pk_test_id PRIMARY KEY,
    Namee VARCHAR2(50) NOT NULL,
    NormalRange VARCHAR2(70),
    Costt NUMBER
);

CREATE TABLE Patient_Lab_Tests (
    PatientID NUMBER NOT NULL,
    TestID NUMBER NOT NULL,
    DateOfTest DATE NOT NULL,
    ResultValue VARCHAR2(50),
    CONSTRAINT pk_patient_labtest PRIMARY KEY (PatientID, TestID, DateOfTest),
    CONSTRAINT fk_patient_labtest_patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    CONSTRAINT fk_patient_labtest_test FOREIGN KEY (TestID) REFERENCES Laboratory_Test(TestID)
);


CREATE TABLE Billing (
    BillID NUMBER CONSTRAINT pk_billt_id PRIMARY KEY,
    PatientID NUMBER NOT NULL,
    DateIssued DATE NOT NULL,
    TotalAmount NUMBER,
    Status VARCHAR2(50),
    CONSTRAINT fk_bill_patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

CREATE TABLE Insurance_Claim (
    ClaimID NUMBER CONSTRAINT pk_claim_id PRIMARY KEY,
    ClaimAmount NUMBER,
    DateOfClaim DATE,
    Status VARCHAR2(50)
);

CREATE TABLE Associated_With_BI (
    BillID NUMBER NOT NULL,
    ClaimID NUMBER,
    CONSTRAINT pk_associated_with_bi PRIMARY KEY (BillID, ClaimID),
    CONSTRAINT fk_associated_with_bi_bill FOREIGN KEY (BillID) REFERENCES Billing(BillID),
    CONSTRAINT fk_associated_with_bi_claim FOREIGN KEY (ClaimID) REFERENCES Insurance_Claim(ClaimID)
);

CREATE OR REPLACE VIEW Patient_overview_view AS
SELECT
    p.PatientID,
    p.Namee AS PatientName,
    p.DateOfBirth,
    p.Gender,
    p.ContactNumber,
    p.EmergencyContact,
    pt.TreatmentID,
    pt.DateOfTreatment AS TreatmentDate,
    pt.Outcome AS TreatmentOutcome,
    t.Descriptionn AS TreatmentDescription,
    pr.PrescriptionID,
    m.Namee AS MedicationName,
    m.Descriptionn AS MedicationDescription,
    m.SideEffects,
    pr.Dosage,
    pr.Frequency,
    pr.StartDate AS PrescriptionStartDate,
    pr.EndDate AS PrescriptionEndDate
FROM
    Patient p
LEFT JOIN Patient_Treatment pt ON p.PatientID = pt.PatientID
LEFT JOIN Treatment t ON pt.TreatmentID = t.TreatmentID
LEFT JOIN Prescription pr ON p.PatientID = pr.PatientID
LEFT JOIN Medication m ON pr.MedicationID = m.MedicationID;

CREATE OR REPLACE VIEW Appointment_schedule_view AS
SELECT
    a.AppointmentID,
    a.PatientID,
    a.DoctorID,
    a.AppointmentDate,
    a.Purpose,
    s.StaffID,
    s.Namee AS DoctorName,
    s.Positionn AS DoctorPosition,
    s.Department AS DoctorDepartment,
    s.ContactNumber AS DoctorContact,
    s.AvailableTimeStart AS DoctorAvailableTimeStart,
    s.AvailableTimeEnd AS DoctorAvailableTimeEnd
FROM
    Appointment a
JOIN Staff s ON a.DoctorID = s.StaffID;

CREATE OR REPLACE VIEW Invoice_summary_view AS
SELECT
    b.BillID,
    b.PatientID,
    b.DateIssued,
    b.TotalAmount,
    b.Status AS BillingStatus,
    ic.ClaimID,
    ic.ClaimAmount,
    ic.DateOfClaim,
    ic.Status AS InsuranceClaimStatus,
    p.Namee AS PatientName,
    p.ContactNumber AS PatientContact
FROM
    Billing b
LEFT JOIN Associated_With_BI awb ON b.BillID = awb.BillID
LEFT JOIN Insurance_Claim ic ON awb.ClaimID = ic.ClaimID
JOIN Patient p ON b.PatientID = p.PatientID;

CREATE OR REPLACE TRIGGER trg_update_treatment_cost
AFTER UPDATE ON Treatment
FOR EACH ROW
BEGIN
    UPDATE Patient_Treatment pt
    SET pt.Outcome = pt.Outcome + (:NEW.Costt - :OLD.Costt)
    WHERE pt.TreatmentID = :NEW.TreatmentID;
END;
/

CREATE OR REPLACE TRIGGER trg_prescription_expiry_notification
BEFORE INSERT OR UPDATE ON Prescription
FOR EACH ROW
DECLARE
    v_expiry_date DATE;
BEGIN
    v_expiry_date := SYSDATE;

    IF :NEW.EndDate IS NOT NULL AND :NEW.EndDate < v_expiry_date THEN
        DBMS_OUTPUT.PUT_LINE('Prescription is about to expire!');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_appointment_time_constraint
BEFORE INSERT OR UPDATE ON Appointment
FOR EACH ROW
DECLARE
    v_existing_appointment_count NUMBER;
BEGIN
    v_existing_appointment_count := 0;

    IF INSERTING THEN
        SELECT COUNT(*)
        INTO v_existing_appointment_count
        FROM Appointment
        WHERE DoctorID = :NEW.DoctorID
          AND (
                (:NEW.AppointmentDate BETWEEN AppointmentDate - INTERVAL '10' MINUTE AND AppointmentDate) OR
                (AppointmentDate BETWEEN :NEW.AppointmentDate AND :NEW.AppointmentDate + INTERVAL '10' MINUTE)
              );

    ELSIF UPDATING THEN
        SELECT COUNT(*)
        INTO v_existing_appointment_count
        FROM Appointment
        WHERE DoctorID = :NEW.DoctorID
          AND AppointmentID != :NEW.AppointmentID
          AND (
                (:NEW.AppointmentDate BETWEEN AppointmentDate - INTERVAL '10' MINUTE AND AppointmentDate) OR
                (AppointmentDate BETWEEN :NEW.AppointmentDate AND :NEW.AppointmentDate + INTERVAL '10' MINUTE)
              );

    END IF;

    IF v_existing_appointment_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Two appointments must have at least 10 minutes gap.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_check_claim_amount
BEFORE INSERT OR UPDATE ON Associated_With_BI
FOR EACH ROW
DECLARE
    v_total_amount NUMBER;
    v_claim_amount NUMBER;
BEGIN
    SELECT TotalAmount
    INTO v_total_amount
    FROM Billing
    WHERE BillID = :NEW.BillID;

    SELECT ClaimAmount
    INTO v_claim_amount
    FROM Insurance_Claim
    WHERE ClaimID = :NEW.ClaimID;

    IF v_claim_amount > v_total_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Claim amount cannot be higher than the total amount.');
    END IF;
END trg_check_claim_amount;
/

CREATE OR REPLACE TRIGGER trg_check_dates
BEFORE INSERT OR UPDATE ON Associated_With_BI
FOR EACH ROW
DECLARE
    v_date_issued DATE;
    v_date_claimed DATE;
BEGIN
    SELECT DateIssued
    INTO v_date_issued
    FROM Billing
    WHERE BillID = :NEW.BillID;

    SELECT DateOfClaim
    INTO v_date_claimed
    FROM Insurance_Claim
    WHERE ClaimID = :NEW.ClaimID;

    IF v_date_issued > v_date_claimed THEN
        RAISE_APPLICATION_ERROR(-20001, 'DateIssued should be earlier than DateOfClaim.');
    END IF;
END trg_check_dates;
/

INSERT INTO Patient VALUES (1, 'John Doe', TO_DATE('1990-01-15', 'YYYY-MM-DD'), 'Male', '123 Main St', '555-1234', '555-5678', 'ABC Insurance');
INSERT INTO Patient VALUES (2, 'Jane Smith', TO_DATE('1985-05-22', 'YYYY-MM-DD'), 'Female', '456 Oak St', '556-5678', '555-9012', 'XYZ Insurance');
INSERT INTO Patient VALUES (3, 'Robert Johnson', TO_DATE('1978-09-10', 'YYYY-MM-DD'), 'Male', '789 Pine St', '557-7891', '555-3456', 'DEF Insurance');
INSERT INTO Patient VALUES (4, 'Emily White', TO_DATE('1995-03-08', 'YYYY-MM-DD'), 'Female', '234 Cedar St', '558-2345', '555-6789', 'GHI Insurance');
INSERT INTO Patient VALUES (5, 'Michael Davis', TO_DATE('1982-11-30', 'YYYY-MM-DD'), 'Male', '567 Elm St', '559-4567', '555-7890', 'JKL Insurance');
INSERT INTO Patient VALUES (6, 'Samantha Miller', TO_DATE('1993-07-17', 'YYYY-MM-DD'), 'Female', '890 Birch St', '560-6789', '555-9012', 'MNO Insurance');
INSERT INTO Patient VALUES (7, 'Daniel Brown', TO_DATE('1974-04-25', 'YYYY-MM-DD'), 'Male', '123 Maple St', '561-8901', '555-1234', 'PQR Insurance');
INSERT INTO Patient VALUES (8, 'Olivia Taylor', TO_DATE('1988-12-03', 'YYYY-MM-DD'), 'Female', '456 Oak St', '562-9012', '555-2345', 'STU Insurance');
INSERT INTO Patient VALUES (9, 'William Harris', TO_DATE('1991-06-20', 'YYYY-MM-DD'), 'Male', '789 Pine St', '563-2346', '555-5678', 'VWX Insurance');
INSERT INTO Patient VALUES (10, 'Ava Martinez', TO_DATE('1980-02-14', 'YYYY-MM-DD'), 'Female', '234 Cedar St', '564-3456', '555-6789', 'YZA Insurance');
INSERT INTO Patient VALUES (11, 'Liam Robinson', TO_DATE('1998-08-07', 'YYYY-MM-DD'), 'Male', '567 Elm St', '565-5678', '555-7890', 'BCD Insurance');
INSERT INTO Patient VALUES (12, 'Emma Garcia', TO_DATE('1986-01-01', 'YYYY-MM-DD'), 'Female', '890 Birch St', '566-6789', '555-9012', 'EFG Insurance');
INSERT INTO Patient VALUES (13, 'Mason Wright', TO_DATE('1979-05-18', 'YYYY-MM-DD'), 'Male', '123 Maple St', '567-7890', '555-1234', 'HIJ Insurance');
INSERT INTO Patient VALUES (14, 'Sophia Martinez', TO_DATE('1994-09-23', 'YYYY-MM-DD'), 'Female', '456 Oak St', '568-8901', '555-2345', 'KLM Insurance');
INSERT INTO Patient VALUES (15, 'Jackson Taylor', TO_DATE('1983-03-12', 'YYYY-MM-DD'), 'Male', '789 Pine St', '569-9012', '555-3456', 'NOP Insurance');
INSERT INTO Patient VALUES (16, 'Olivia Davis', TO_DATE('1992-07-29', 'YYYY-MM-DD'), 'Female', '234 Cedar St', '570-1234', '555-5678', 'QRS Insurance');
INSERT INTO Patient VALUES (17, 'Ethan White', TO_DATE('1975-02-06', 'YYYY-MM-DD'), 'Male', '567 Elm St', '571-2345', '555-6789', 'TUV Insurance');
INSERT INTO Patient VALUES (18, 'Ava Smith', TO_DATE('1987-11-15', 'YYYY-MM-DD'), 'Female', '890 Birch St', '572-5678', '555-7890', 'WXY Insurance');
INSERT INTO Patient VALUES (19, 'Liam Johnson', TO_DATE('1981-04-03', 'YYYY-MM-DD'), 'Male', '123 Maple St', '573-6789', '555-9012', 'YZA Insurance');
INSERT INTO Patient VALUES (20, 'Emma Harris', TO_DATE('1996-10-28', 'YYYY-MM-DD'), 'Female', '456 Oak St', '574-7890', '555-1234', 'BCD Insurance');

INSERT INTO Medication VALUES (1, 'Aspirin', 'Pain reliever and anti-inflammatory', 'Nausea, stomach pain');
INSERT INTO Medication VALUES (2, 'Ibuprofen', 'Nonsteroidal anti-inflammatory drug (NSAID)', 'Heartburn, rash');
INSERT INTO Medication VALUES (3, 'Acetaminophen', 'Pain reliever and fever reducer', 'Liver damage');
INSERT INTO Medication VALUES (4, 'Lisinopril', 'Angiotensin-converting enzyme (ACE) inhibitor', 'Cough, dizziness');
INSERT INTO Medication VALUES (5, 'Atorvastatin', 'Statins for cholesterol control', 'Muscle pain, liver problems');
INSERT INTO Medication VALUES (6, 'Metformin', 'Antidiabetic medication', 'Nausea, diarrhea');
INSERT INTO Medication VALUES (7, 'Levothyroxine', 'Thyroid hormone replacement', 'Weight loss, insomnia');
INSERT INTO Medication VALUES (8, 'Amlodipine', 'Calcium channel blocker', 'Swelling in ankles, dizziness');
INSERT INTO Medication VALUES (9, 'Hydrochlorothiazide', 'Diuretic for blood pressure', 'Low potassium, dizziness');
INSERT INTO Medication VALUES (10, 'Omeprazole', 'Proton pump inhibitor (PPI)', 'Abdominal pain, nausea');
INSERT INTO Medication VALUES (11, 'Metoprolol', 'Beta-blocker for heart conditions', 'Fatigue, slow heartbeat');
INSERT INTO Medication VALUES (12, 'Sertraline', 'Selective serotonin reuptake inhibitor (SSRI)', 'Insomnia, nausea');
INSERT INTO Medication VALUES (13, 'Ciprofloxacin', 'Fluoroquinolone antibiotic', 'Tendon rupture, nausea');
INSERT INTO Medication VALUES (14, 'Albuterol', 'Bronchodilator for asthma', 'Shakiness, increased heart rate');
INSERT INTO Medication VALUES (15, 'Warfarin', 'Anticoagulant (blood thinner)', 'Bleeding, hair loss');
INSERT INTO Medication VALUES (16, 'Clopidogrel', 'Antiplatelet drug', 'Bleeding, abdominal pain');
INSERT INTO Medication VALUES (17, 'Duloxetine', 'Serotonin-norepinephrine reuptake inhibitor (SNRI)', 'Nausea, dry mouth');
INSERT INTO Medication VALUES (18, 'Losartan', 'Angiotensin II receptor blocker (ARB)', 'Dizziness, fatigue');
INSERT INTO Medication VALUES (19, 'Simvastatin', 'Statins for cholesterol control', 'Muscle pain, liver problems');
INSERT INTO Medication VALUES (20, 'Pantoprazole', 'Proton pump inhibitor (PPI)', 'Headache, diarrhea');

INSERT INTO Prescription VALUES (1, 1, 1, 'Take 1 tablet with food', 'Twice a day', TO_DATE('2023-03-01', 'YYYY-MM-DD'), TO_DATE('2023-03-15', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (2, 2, 2, 'Take 1 tablet with water', 'Every 4 hours', TO_DATE('2023-03-02', 'YYYY-MM-DD'), TO_DATE('2023-03-16', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (3, 3, 3, 'Take 2 tablets as needed', 'Up to 3 times a day', TO_DATE('2023-03-03', 'YYYY-MM-DD'), TO_DATE('2023-03-17', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (4, 4, 4, 'Take 1 tablet in the morning', 'Once a day', TO_DATE('2023-03-04', 'YYYY-MM-DD'), TO_DATE('2023-03-18', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (5, 5, 5, 'Take 1 tablet at bedtime', 'Once a day', TO_DATE('2023-03-05', 'YYYY-MM-DD'), TO_DATE('2023-03-19', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (6, 6, 6, 'Take 1 tablet with meals', 'Twice a day', TO_DATE('2023-03-06', 'YYYY-MM-DD'), TO_DATE('2023-03-20', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (7, 7, 7, 'Take 1 tablet in the morning', 'Once a day', TO_DATE('2023-03-07', 'YYYY-MM-DD'), TO_DATE('2023-03-21', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (8, 8, 8, 'Take 1 tablet with water', 'Twice a day', TO_DATE('2023-03-08', 'YYYY-MM-DD'), TO_DATE('2023-03-22', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (9, 9, 9, 'Take 1 tablet with meals', 'Once a day', TO_DATE('2023-03-09', 'YYYY-MM-DD'), TO_DATE('2023-03-23', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (10, 10, 10, 'Take 1 tablet in the morning', 'Once a day', TO_DATE('2023-03-10', 'YYYY-MM-DD'), TO_DATE('2023-03-24', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (11, 11, 11, 'Take 1 tablet with food', 'Twice a day', TO_DATE('2023-03-11', 'YYYY-MM-DD'), TO_DATE('2023-03-25', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (12, 12, 12, 'Take 1 tablet in the evening', 'Once a day', TO_DATE('2023-03-12', 'YYYY-MM-DD'), TO_DATE('2023-03-26', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (13, 13, 13, 'Take 1 tablet with water', 'Twice a day', TO_DATE('2023-03-13', 'YYYY-MM-DD'), TO_DATE('2023-03-27', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (14, 14, 14, 'Take 1 inhalation as needed', 'Up to 4 times a day', TO_DATE('2023-03-14', 'YYYY-MM-DD'), TO_DATE('2023-03-28', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (15, 15, 15, 'Take 1 tablet with water', 'Once a day', TO_DATE('2023-03-15', 'YYYY-MM-DD'), TO_DATE('2023-03-29', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (16, 16, 16, 'Take 1 tablet with food', 'Once a day', TO_DATE('2023-03-16', 'YYYY-MM-DD'), TO_DATE('2023-03-30', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (17, 17, 17, 'Take 1 capsule with water', 'Once a day', TO_DATE('2023-03-17', 'YYYY-MM-DD'), TO_DATE('2023-03-31', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (18, 18, 18, 'Take 1 tablet with meals', 'Twice a day', TO_DATE('2023-03-18', 'YYYY-MM-DD'), TO_DATE('2023-04-01', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (19, 19, 19, 'Take 1 tablet with water', 'Once a day', TO_DATE('2023-03-19', 'YYYY-MM-DD'), TO_DATE('2023-04-02', 'YYYY-MM-DD'));
INSERT INTO Prescription VALUES (20, 20, 20, 'Take 1 tablet with food', 'Twice a day', TO_DATE('2023-03-20', 'YYYY-MM-DD'), TO_DATE('2023-04-03', 'YYYY-MM-DD'));

INSERT INTO Treatment VALUES (1, 'Physical Therapy', 75);
INSERT INTO Treatment VALUES (2, 'Counseling', 100);
INSERT INTO Treatment VALUES (3, 'Surgery', 5000);
INSERT INTO Treatment VALUES (4, 'Dental Cleaning', 150);
INSERT INTO Treatment VALUES (5, 'Chiropractic Adjustment', 80);
INSERT INTO Treatment VALUES (6, 'Radiation Therapy', 3000);
INSERT INTO Treatment VALUES (7, 'Chemotherapy', 4000);
INSERT INTO Treatment VALUES (8, 'Eye Exam', 50);
INSERT INTO Treatment VALUES (9, 'Orthopedic Consultation', 120);
INSERT INTO Treatment VALUES (10, 'Mental Health Evaluation', 90);
INSERT INTO Treatment VALUES (11, 'Cardiac Rehabilitation', 200);
INSERT INTO Treatment VALUES (12, 'Gastroenterology Consult', 150);
INSERT INTO Treatment VALUES (13, 'Allergy Testing', 80);
INSERT INTO Treatment VALUES (14, 'Prenatal Care', 300);
INSERT INTO Treatment VALUES (15, 'Speech Therapy', 120);
INSERT INTO Treatment VALUES (16, 'Occupational Therapy', 150);
INSERT INTO Treatment VALUES (17, 'Pulmonary Function Test', 100);
INSERT INTO Treatment VALUES (18, 'Neurological Evaluation', 250);
INSERT INTO Treatment VALUES (19, 'Sleep Study', 200);
INSERT INTO Treatment VALUES (20, 'Nutritional Counseling', 80);

INSERT INTO Patient_Treatment VALUES (1, 1, TO_DATE('2023-01-20', 'YYYY-MM-DD'), 'Recovered');
INSERT INTO Patient_Treatment VALUES (2, 2, TO_DATE('2023-02-25', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (3, 3, TO_DATE('2023-03-01', 'YYYY-MM-DD'), 'Improved');
INSERT INTO Patient_Treatment VALUES (4, 4, TO_DATE('2023-03-06', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (5, 5, TO_DATE('2023-03-11', 'YYYY-MM-DD'), 'Recovered');
INSERT INTO Patient_Treatment VALUES (6, 6, TO_DATE('2023-03-16', 'YYYY-MM-DD'), 'Improved');
INSERT INTO Patient_Treatment VALUES (7, 7, TO_DATE('2023-03-21', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (8, 8, TO_DATE('2023-03-26', 'YYYY-MM-DD'), 'Recovered');
INSERT INTO Patient_Treatment VALUES (9, 9, TO_DATE('2023-03-31', 'YYYY-MM-DD'), 'Improved');
INSERT INTO Patient_Treatment VALUES (10, 10, TO_DATE('2023-04-05', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (11, 11, TO_DATE('2023-04-10', 'YYYY-MM-DD'), 'Recovered');
INSERT INTO Patient_Treatment VALUES (12, 12, TO_DATE('2023-04-15', 'YYYY-MM-DD'), 'Improved');
INSERT INTO Patient_Treatment VALUES (13, 13, TO_DATE('2023-04-20', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (14, 14, TO_DATE('2023-04-25', 'YYYY-MM-DD'), 'Recovered');
INSERT INTO Patient_Treatment VALUES (15, 15, TO_DATE('2023-04-30', 'YYYY-MM-DD'), 'Improved');
INSERT INTO Patient_Treatment VALUES (16, 16, TO_DATE('2023-05-05', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (17, 17, TO_DATE('2023-05-10', 'YYYY-MM-DD'), 'Recovered');
INSERT INTO Patient_Treatment VALUES (18, 18, TO_DATE('2023-05-15', 'YYYY-MM-DD'), 'Improved');
INSERT INTO Patient_Treatment VALUES (19, 19, TO_DATE('2023-05-20', 'YYYY-MM-DD'), 'Stable');
INSERT INTO Patient_Treatment VALUES (20, 20, TO_DATE('2023-05-25', 'YYYY-MM-DD'), 'Recovered');

INSERT INTO Staff VALUES (1, 'Dr. Smith', 'Doctor', 'Internal Medicine', '555-1234', '789 Oak St', 120000, TO_DATE('2010-05-01', 'YYYY-MM-DD'), TO_DATE('09:00', 'HH24:MI'), TO_DATE('17:00', 'HH24:MI'));
INSERT INTO Staff VALUES (2, 'Nurse Johnson', 'Nurse', 'Emergency Medicine', '555-5678', '890 Maple St', 80000, TO_DATE('2015-02-15', 'YYYY-MM-DD'), TO_DATE('08:00', 'HH24:MI'), TO_DATE('16:00', 'HH24:MI'));
INSERT INTO Staff VALUES (3, 'Dr. Brown', 'Doctor', 'Cardiology', '555-8901', '123 Pine St', 130000, TO_DATE('2012-10-10', 'YYYY-MM-DD'), TO_DATE('10:00', 'HH24:MI'), TO_DATE('18:00', 'HH24:MI'));
INSERT INTO Staff VALUES (4, 'Nurse Anderson', 'Nurse', 'Orthopedics', '555-2345', '456 Cedar St', 75000, TO_DATE('2017-07-20', 'YYYY-MM-DD'), TO_DATE('07:30', 'HH24:MI'), TO_DATE('15:30', 'HH24:MI'));
INSERT INTO Staff VALUES (5, 'Dr. Garcia', 'Doctor', 'Dermatology', '555-4567', '789 Birch St', 110000, TO_DATE('2008-03-05', 'YYYY-MM-DD'), TO_DATE('11:30', 'HH24:MI'), TO_DATE('19:30', 'HH24:MI'));
INSERT INTO Staff VALUES (6, 'Nurse Miller', 'Nurse', 'Pediatrics', '555-6789', '890 Oak St', 78000, TO_DATE('2016-01-15', 'YYYY-MM-DD'), TO_DATE('08:30', 'HH24:MI'), TO_DATE('16:30', 'HH24:MI'));
INSERT INTO Staff VALUES (7, 'Dr. Taylor', 'Doctor', 'Neurology', '555-9012', '123 Maple St', 125000, TO_DATE('2013-06-22', 'YYYY-MM-DD'), TO_DATE('10:30', 'HH24:MI'), TO_DATE('18:30', 'HH24:MI'));
INSERT INTO Staff VALUES (8, 'Nurse White', 'Nurse', 'Gastroenterology', '555-1234', '456 Cedar St', 80000, TO_DATE('2018-11-10', 'YYYY-MM-DD'), TO_DATE('07:00', 'HH24:MI'), TO_DATE('15:00', 'HH24:MI'));
INSERT INTO Staff VALUES (9, 'Dr. Robinson', 'Doctor', 'Ophthalmology', '555-5678', '789 Pine St', 115000, TO_DATE('2009-09-01', 'YYYY-MM-DD'), TO_DATE('09:00', 'HH24:MI'), TO_DATE('17:00', 'HH24:MI'));
INSERT INTO Staff VALUES (10, 'Nurse Harris', 'Nurse', 'Urology', '555-2345', '890 Cedar St', 76000, TO_DATE('2014-04-12', 'YYYY-MM-DD'), TO_DATE('08:00', 'HH24:MI'), TO_DATE('16:00', 'HH24:MI'));
INSERT INTO Staff VALUES (11, 'Dr. Martinez', 'Doctor', 'Rheumatology', '555-6789', '123 Birch St', 120000, TO_DATE('2011-02-28', 'YYYY-MM-DD'), TO_DATE('11:00', 'HH24:MI'), TO_DATE('19:00', 'HH24:MI'));
INSERT INTO Staff VALUES (12, 'Nurse Davis', 'Nurse', 'Oncology', '555-8901', '456 Oak St', 82000, TO_DATE('2019-05-18', 'YYYY-MM-DD'), TO_DATE('07:30', 'HH24:MI'), TO_DATE('15:30', 'HH24:MI'));
INSERT INTO Staff VALUES (13, 'Dr. Miller', 'Doctor', 'Endocrinology', '555-1234', '789 Maple St', 110000, TO_DATE('2007-08-15', 'YYYY-MM-DD'), TO_DATE('10:00', 'HH24:MI'), TO_DATE('18:00', 'HH24:MI'));
INSERT INTO Staff VALUES (14, 'Nurse Taylor', 'Nurse', 'Hematology', '555-5678', '890 Pine St', 78000, TO_DATE('2015-12-01', 'YYYY-MM-DD'), TO_DATE('08:30', 'HH24:MI'), TO_DATE('16:30', 'HH24:MI'));
INSERT INTO Staff VALUES (15, 'Dr. White', 'Doctor', 'Allergy and Immunology', '555-9012', '123 Cedar St', 125000, TO_DATE('2010-11-08', 'YYYY-MM-DD'), TO_DATE('10:30', 'HH24:MI'), TO_DATE('18:30', 'HH24:MI'));
INSERT INTO Staff VALUES (16, 'Nurse Robinson', 'Nurse', 'Psychiatry', '555-2345', '456 Birch St', 80000, TO_DATE('2016-03-22', 'YYYY-MM-DD'), TO_DATE('07:00', 'HH24:MI'), TO_DATE('15:00', 'HH24:MI'));
INSERT INTO Staff VALUES (17, 'Dr. Harris', 'Doctor', 'Pulmonology', '555-6789', '789 Oak St', 115000, TO_DATE('2013-09-15', 'YYYY-MM-DD'), TO_DATE('09:00', 'HH24:MI'), TO_DATE('17:00', 'HH24:MI'));
INSERT INTO Staff VALUES (18, 'Nurse Martinez', 'Nurse', 'Nephrology', '555-8901', '890 Cedar St', 76000, TO_DATE('2018-05-01', 'YYYY-MM-DD'), TO_DATE('08:00', 'HH24:MI'), TO_DATE('16:00', 'HH24:MI'));
INSERT INTO Staff VALUES (19, 'Dr. Davis', 'Doctor', 'Dental Medicine', '555-1234', '123 Maple St', 120000, TO_DATE('2011-01-12', 'YYYY-MM-DD'), TO_DATE('11:00', 'HH24:MI'), TO_DATE('19:00', 'HH24:MI'));
INSERT INTO Staff VALUES (20, 'Nurse Smith', 'Nurse', 'Geriatrics', '555-5678', '456 Cedar St', 78000, TO_DATE('2014-06-30', 'YYYY-MM-DD'), TO_DATE('08:30', 'HH24:MI'), TO_DATE('16:30', 'HH24:MI'));

INSERT INTO Appointment VALUES (1, 1, 1, TO_TIMESTAMP('2023-03-01 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'General Checkup');
INSERT INTO Appointment VALUES (2, 2, 1, TO_TIMESTAMP('2023-03-02 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Follow-up');
INSERT INTO Appointment VALUES (3, 3, 2, TO_TIMESTAMP('2023-03-03 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Physical Examination');
INSERT INTO Appointment VALUES (4, 4, 2, TO_TIMESTAMP('2023-03-04 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Consultation');
INSERT INTO Appointment VALUES (5, 5, 3, TO_TIMESTAMP('2023-03-05 13:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'X-ray Appointment');
INSERT INTO Appointment VALUES (6, 6, 3, TO_TIMESTAMP('2023-03-06 15:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Follow-up');
INSERT INTO Appointment VALUES (7, 7, 4, TO_TIMESTAMP('2023-03-07 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'General Checkup');
INSERT INTO Appointment VALUES (8, 8, 4, TO_TIMESTAMP('2023-03-08 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Consultation');
INSERT INTO Appointment VALUES (9, 9, 5, TO_TIMESTAMP('2023-03-09 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Follow-up');
INSERT INTO Appointment VALUES (10, 10, 5, TO_TIMESTAMP('2023-03-10 14:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Physical Examination');
INSERT INTO Appointment VALUES (11, 11, 6, TO_TIMESTAMP('2023-03-11 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'X-ray Appointment');
INSERT INTO Appointment VALUES (12, 12, 6, TO_TIMESTAMP('2023-03-12 16:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Follow-up');
INSERT INTO Appointment VALUES (13, 13, 7, TO_TIMESTAMP('2023-03-13 11:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'General Checkup');
INSERT INTO Appointment VALUES (14, 14, 7, TO_TIMESTAMP('2023-03-14 13:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Consultation');
INSERT INTO Appointment VALUES (15, 15, 8, TO_TIMESTAMP('2023-03-15 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'X-ray Appointment');
INSERT INTO Appointment VALUES (16, 16, 8, TO_TIMESTAMP('2023-03-16 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Follow-up');
INSERT INTO Appointment VALUES (17, 17, 9, TO_TIMESTAMP('2023-03-17 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'General Checkup');
INSERT INTO Appointment VALUES (18, 18, 9, TO_TIMESTAMP('2023-03-18 12:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Physical Examination');
INSERT INTO Appointment VALUES (19, 19, 10, TO_TIMESTAMP('2023-03-19 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'X-ray Appointment');
INSERT INTO Appointment VALUES (20, 20, 10, TO_TIMESTAMP('2023-03-20 16:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Consultation');


INSERT INTO Laboratory_Test VALUES (1, 'Blood Test', 'Normal range: 70-120 mg/dL', 50);
INSERT INTO Laboratory_Test VALUES (2, 'Urine Analysis', 'Normal range: Clear, yellow color', 30);
INSERT INTO Laboratory_Test VALUES (3, 'X-ray', 'Normal result: No abnormalities detected', 100);
INSERT INTO Laboratory_Test VALUES (4, 'MRI Scan', 'Normal result: Detailed images of internal structures', 200);
INSERT INTO Laboratory_Test VALUES (5, 'CT Scan', 'Normal result: Cross-sectional images of the body', 150);
INSERT INTO Laboratory_Test VALUES (6, 'ECG', 'Normal result: Regular heart rhythm', 40);
INSERT INTO Laboratory_Test VALUES (7, 'Ultrasound', 'Normal result: Sound waves for internal imaging', 80);
INSERT INTO Laboratory_Test VALUES (8, 'Colonoscopy', 'Normal result: Visualization of the colon', 120);
INSERT INTO Laboratory_Test VALUES (9, 'Pap Smear', 'Normal result: Detection of cervical abnormalities', 60);
INSERT INTO Laboratory_Test VALUES (10, 'Biopsy', 'Normal result: Examination of tissue sample', 180);
INSERT INTO Laboratory_Test VALUES (11, 'Genetic Testing', 'Normal result: Analysis of DNA for genetic disorders', 250);
INSERT INTO Laboratory_Test VALUES (12, 'Allergy Test', 'Normal result: Identification of allergic reactions', 70);
INSERT INTO Laboratory_Test VALUES (13, 'Spirometry', 'Normal result: Measurement of lung function', 90);
INSERT INTO Laboratory_Test VALUES (14, 'Thyroid Function Test', 'Normal range: TSH, T3, T4 levels', 55);
INSERT INTO Laboratory_Test VALUES (15, 'Doppler Ultrasound', 'Normal result: Blood flow measurement', 110);
INSERT INTO Laboratory_Test VALUES (16, 'Bone Density Test', 'Normal result: Assessment of bone strength', 130);
INSERT INTO Laboratory_Test VALUES (17, 'Liver Function Test', 'Normal range: ALT, AST, ALP levels', 65);
INSERT INTO Laboratory_Test VALUES (18, 'C-Reactive Protein Test', 'Normal range: Indicator of inflammation', 45);
INSERT INTO Laboratory_Test VALUES (19, 'Hemoglobin A1c Test', 'Normal range: Diabetes management', 75);
INSERT INTO Laboratory_Test VALUES (20, 'HIV Test', 'Normal result: Detection of HIV infection', 95);
 
INSERT INTO Patient_Lab_Tests VALUES (1, 1, TO_DATE('2023-01-20', 'YYYY-MM-DD'), '80');
INSERT INTO Patient_Lab_Tests VALUES (2, 2, TO_DATE('2023-02-25', 'YYYY-MM-DD'), 'Normal');
INSERT INTO Patient_Lab_Tests VALUES (3, 3, TO_DATE('2023-03-01', 'YYYY-MM-DD'), '105');
INSERT INTO Patient_Lab_Tests VALUES (4, 4, TO_DATE('2023-03-06', 'YYYY-MM-DD'), '92');
INSERT INTO Patient_Lab_Tests VALUES (5, 5, TO_DATE('2023-03-11', 'YYYY-MM-DD'), '120');
INSERT INTO Patient_Lab_Tests VALUES (6, 6, TO_DATE('2023-03-16', 'YYYY-MM-DD'), '88');
INSERT INTO Patient_Lab_Tests VALUES (7, 7, TO_DATE('2023-03-21', 'YYYY-MM-DD'), '75');
INSERT INTO Patient_Lab_Tests VALUES (8, 8, TO_DATE('2023-03-26', 'YYYY-MM-DD'), '110');
INSERT INTO Patient_Lab_Tests VALUES (9, 9, TO_DATE('2023-03-31', 'YYYY-MM-DD'), '95');
INSERT INTO Patient_Lab_Tests VALUES (10, 10, TO_DATE('2023-04-05', 'YYYY-MM-DD'), '85');
INSERT INTO Patient_Lab_Tests VALUES (11, 11, TO_DATE('2023-04-10', 'YYYY-MM-DD'), '98');
INSERT INTO Patient_Lab_Tests VALUES (12, 12, TO_DATE('2023-04-15', 'YYYY-MM-DD'), '112');
INSERT INTO Patient_Lab_Tests VALUES (13, 13, TO_DATE('2023-04-20', 'YYYY-MM-DD'), '88');
INSERT INTO Patient_Lab_Tests VALUES (14, 14, TO_DATE('2023-04-25', 'YYYY-MM-DD'), '96');
INSERT INTO Patient_Lab_Tests VALUES (15, 15, TO_DATE('2023-04-30', 'YYYY-MM-DD'), '105');
INSERT INTO Patient_Lab_Tests VALUES (16, 16, TO_DATE('2023-05-05', 'YYYY-MM-DD'), '82');
INSERT INTO Patient_Lab_Tests VALUES (17, 17, TO_DATE('2023-05-10', 'YYYY-MM-DD'), '94');
INSERT INTO Patient_Lab_Tests VALUES (18, 18, TO_DATE('2023-05-15', 'YYYY-MM-DD'), '100');
INSERT INTO Patient_Lab_Tests VALUES (19, 19, TO_DATE('2023-05-20', 'YYYY-MM-DD'), '78');
INSERT INTO Patient_Lab_Tests VALUES (20, 20, TO_DATE('2023-05-25', 'YYYY-MM-DD'), '102');
 
INSERT INTO Billing VALUES (1, 1, TO_DATE('2023-03-01', 'YYYY-MM-DD'), 150, 'Paid');
INSERT INTO Billing VALUES (2, 2, TO_DATE('2023-03-02', 'YYYY-MM-DD'), 200, 'Pending');
INSERT INTO Billing VALUES (3, 3, TO_DATE('2023-03-03', 'YYYY-MM-DD'), 120, 'Paid');
INSERT INTO Billing VALUES (4, 4, TO_DATE('2023-03-04', 'YYYY-MM-DD'), 180, 'Pending');
INSERT INTO Billing VALUES (5, 5, TO_DATE('2023-03-05', 'YYYY-MM-DD'), 250, 'Paid');
INSERT INTO Billing VALUES (6, 6, TO_DATE('2023-03-06', 'YYYY-MM-DD'), 160, 'Pending');
INSERT INTO Billing VALUES (7, 7, TO_DATE('2023-03-07', 'YYYY-MM-DD'), 190, 'Paid');
INSERT INTO Billing VALUES (8, 8, TO_DATE('2023-03-08', 'YYYY-MM-DD'), 210, 'Pending');
INSERT INTO Billing VALUES (9, 9, TO_DATE('2023-03-09', 'YYYY-MM-DD'), 140, 'Paid');
INSERT INTO Billing VALUES (10, 10, TO_DATE('2023-03-10', 'YYYY-MM-DD'), 170, 'Pending');
INSERT INTO Billing VALUES (11, 11, TO_DATE('2023-03-11', 'YYYY-MM-DD'), 220, 'Paid');
INSERT INTO Billing VALUES (12, 12, TO_DATE('2023-03-12', 'YYYY-MM-DD'), 130, 'Pending');
INSERT INTO Billing VALUES (13, 13, TO_DATE('2023-03-13', 'YYYY-MM-DD'), 200, 'Paid');
INSERT INTO Billing VALUES (14, 14, TO_DATE('2023-03-14', 'YYYY-MM-DD'), 240, 'Pending');
INSERT INTO Billing VALUES (15, 15, TO_DATE('2023-03-15', 'YYYY-MM-DD'), 180, 'Paid');
INSERT INTO Billing VALUES (16, 16, TO_DATE('2023-03-16', 'YYYY-MM-DD'), 170, 'Pending');
INSERT INTO Billing VALUES (17, 17, TO_DATE('2023-03-17', 'YYYY-MM-DD'), 190, 'Paid');
INSERT INTO Billing VALUES (18, 18, TO_DATE('2023-03-18', 'YYYY-MM-DD'), 210, 'Pending');
INSERT INTO Billing VALUES (19, 19, TO_DATE('2023-03-19', 'YYYY-MM-DD'), 150, 'Paid');
INSERT INTO Billing VALUES (20, 20, TO_DATE('2023-03-20', 'YYYY-MM-DD'), 160, 'Pending');
 
INSERT INTO Insurance_Claim VALUES (1, 10, TO_DATE('2023-03-01', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (2, 12, TO_DATE('2023-03-02', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (3, 13, TO_DATE('2023-03-03', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (4, 14, TO_DATE('2023-03-04', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (5, 15, TO_DATE('2023-03-05', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (6, 16, TO_DATE('2023-03-06', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (7, 17, TO_DATE('2023-03-07', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (8, 18, TO_DATE('2023-03-08', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (9, 19, TO_DATE('2023-03-09', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (10, 20, TO_DATE('2023-03-10', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (11, 21, TO_DATE('2023-03-11', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (12, 22, TO_DATE('2023-03-12', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (13, 23, TO_DATE('2023-03-13', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (14, 24, TO_DATE('2023-03-14', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (15, 25, TO_DATE('2023-03-15', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (16, 26, TO_DATE('2023-03-16', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (17, 27, TO_DATE('2023-03-17', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (18, 28, TO_DATE('2023-03-18', 'YYYY-MM-DD'), 'Pending');
INSERT INTO Insurance_Claim VALUES (19, 29, TO_DATE('2023-03-19', 'YYYY-MM-DD'), 'Approved');
INSERT INTO Insurance_Claim VALUES (20, 30, TO_DATE('2023-03-20', 'YYYY-MM-DD'), 'Pending');

INSERT INTO Associated_With_BI VALUES (1, 1);
INSERT INTO Associated_With_BI VALUES (2, 2);
INSERT INTO Associated_With_BI VALUES (3, 3);
INSERT INTO Associated_With_BI VALUES (4, 4);
INSERT INTO Associated_With_BI VALUES (5, 5);
INSERT INTO Associated_With_BI VALUES (6, 6);
INSERT INTO Associated_With_BI VALUES (7, 7);
INSERT INTO Associated_With_BI VALUES (8, 8);
INSERT INTO Associated_With_BI VALUES (9, 9);
INSERT INTO Associated_With_BI VALUES (10, 10);
INSERT INTO Associated_With_BI VALUES (11, 11);
INSERT INTO Associated_With_BI VALUES (12, 12);
INSERT INTO Associated_With_BI VALUES (13, 13);
INSERT INTO Associated_With_BI VALUES (14, 14);
INSERT INTO Associated_With_BI VALUES (15, 15);
INSERT INTO Associated_With_BI VALUES (16, 16);
INSERT INTO Associated_With_BI VALUES (17, 17);
INSERT INTO Associated_With_BI VALUES (18, 18);
INSERT INTO Associated_With_BI VALUES (19, 19);
INSERT INTO Associated_With_BI VALUES (20, 20);

COMMIT;
