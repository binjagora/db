-- Staff Auditing and Tracking System Database Schema
-- Designed for scalability, performance, and maintainability

-- =============================================
-- REFERENCE/LOOKUP TABLES
-- =============================================

-- Departments table
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_code VARCHAR(10) UNIQUE NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Facilities table
CREATE TABLE facilities (
    facility_id INT PRIMARY KEY AUTO_INCREMENT,
    facility_code VARCHAR(15) UNIQUE NOT NULL,
    facility_name VARCHAR(150) NOT NULL,
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(100),
    department_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Staff roles lookup
CREATE TABLE staff_roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_code VARCHAR(20) UNIQUE NOT NULL,
    role_name VARCHAR(50) NOT NULL,
    description TEXT,
    permission_level INT DEFAULT 1, -- 1=lowest, 10=highest
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staff ranks lookup
CREATE TABLE staff_ranks (
    rank_id INT PRIMARY KEY AUTO_INCREMENT,
    rank_code VARCHAR(20) UNIQUE NOT NULL,
    rank_name VARCHAR(50) NOT NULL,
    description TEXT,
    hierarchy_level INT DEFAULT 1, -- For ordering ranks
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Qualifications lookup
CREATE TABLE qualifications (
    qualification_id INT PRIMARY KEY AUTO_INCREMENT,
    qualification_code VARCHAR(20) UNIQUE NOT NULL,
    qualification_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- e.g., 'Medical', 'Administrative', 'Technical'
    is_certification BOOLEAN DEFAULT FALSE,
    validity_period_months INT, -- NULL if no expiry
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leave types lookup
CREATE TABLE leave_types (
    leave_type_id INT PRIMARY KEY AUTO_INCREMENT,
    leave_code VARCHAR(20) UNIQUE NOT NULL,
    leave_name VARCHAR(50) NOT NULL,
    description TEXT,
    is_paid BOOLEAN DEFAULT TRUE,
    max_days_per_year INT,
    requires_approval BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- CORE ENTITY TABLES
-- =============================================

-- Main staff table
CREATE TABLE staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    date_of_birth DATE,
    hire_date DATE NOT NULL,
    termination_date DATE,
    
    -- Current assignments
    current_department_id INT,
    current_facility_id INT,
    current_role_id INT,
    current_rank_id INT,
    
    -- Employment status
    employment_status ENUM('active', 'inactive', 'terminated', 'suspended') DEFAULT 'active',
    employment_type ENUM('full_time', 'part_time', 'contract', 'temporary') DEFAULT 'full_time',
    
    -- Audit fields
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (current_department_id) REFERENCES departments(department_id),
    FOREIGN KEY (current_facility_id) REFERENCES facilities(facility_id),
    FOREIGN KEY (current_role_id) REFERENCES staff_roles(role_id),
    FOREIGN KEY (current_rank_id) REFERENCES staff_ranks(rank_id),
    
    INDEX idx_employee_number (employee_number),
    INDEX idx_email (email),
    INDEX idx_name (last_name, first_name),
    INDEX idx_department (current_department_id),
    INDEX idx_facility (current_facility_id),
    INDEX idx_status (employment_status)
);

-- System administrators table
CREATE TABLE system_admins (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT UNIQUE NOT NULL,
    admin_role VARCHAR(50) NOT NULL, -- 'superadmin', 'hr_admin', 'facility_admin', etc.
    permissions JSON, -- Store specific permissions as JSON
    access_level INT DEFAULT 1, -- 1-10 scale
    is_active BOOLEAN DEFAULT TRUE,
    assigned_date DATE DEFAULT (CURRENT_DATE),
    assigned_by INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES system_admins(admin_id),
    
    INDEX idx_role (admin_role),
    INDEX idx_access_level (access_level)
);

-- =============================================
-- ASSIGNMENT HISTORY TABLES
-- =============================================

-- Staff assignment history (tracks all department/facility/role changes)
CREATE TABLE staff_assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    department_id INT,
    facility_id INT,
    role_id INT,
    rank_id INT,
    start_date DATE NOT NULL,
    end_date DATE,
    assignment_type ENUM('transfer', 'promotion', 'demotion', 'temporary') DEFAULT 'transfer',
    reason TEXT,
    approved_by INT,
    is_current BOOLEAN DEFAULT FALSE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (facility_id) REFERENCES facilities(facility_id),
    FOREIGN KEY (role_id) REFERENCES staff_roles(role_id),
    FOREIGN KEY (rank_id) REFERENCES staff_ranks(rank_id),
    FOREIGN KEY (approved_by) REFERENCES staff(staff_id),
    FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    
    INDEX idx_staff_current (staff_id, is_current),
    INDEX idx_date_range (start_date, end_date),
    INDEX idx_department_period (department_id, start_date, end_date)
);

-- Staff qualifications (many-to-many with history)
CREATE TABLE staff_qualifications (
    staff_qualification_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    qualification_id INT NOT NULL,
    obtained_date DATE NOT NULL,
    expiry_date DATE,
    issuing_organization VARCHAR(100),
    certificate_number VARCHAR(50),
    verification_status ENUM('pending', 'verified', 'expired', 'revoked') DEFAULT 'pending',
    verification_date DATE,
    verified_by INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (qualification_id) REFERENCES qualifications(qualification_id),
    FOREIGN KEY (verified_by) REFERENCES staff(staff_id),
    
    UNIQUE KEY unique_staff_qualification (staff_id, qualification_id, obtained_date),
    INDEX idx_expiry (expiry_date),
    INDEX idx_verification (verification_status)
);

-- =============================================
-- LEAVE MANAGEMENT TABLES
-- =============================================

-- Leave requests and records
CREATE TABLE leave_records (
    leave_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    leave_type_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days DECIMAL(4,1) NOT NULL,
    reason TEXT,
    status ENUM('pending', 'approved', 'rejected', 'cancelled') DEFAULT 'pending',
    
    -- Approval workflow
    requested_by INT NOT NULL,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_by INT,
    reviewed_at TIMESTAMP,
    approved_by INT,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Additional fields
    is_emergency BOOLEAN DEFAULT FALSE,
    requires_coverage BOOLEAN DEFAULT TRUE,
    coverage_arranged_by INT,
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id),
    FOREIGN KEY (requested_by) REFERENCES staff(staff_id),
    FOREIGN KEY (reviewed_by) REFERENCES staff(staff_id),
    FOREIGN KEY (approved_by) REFERENCES staff(staff_id),
    FOREIGN KEY (coverage_arranged_by) REFERENCES staff(staff_id),
    
    INDEX idx_staff_dates (staff_id, start_date, end_date),
    INDEX idx_status (status),
    INDEX idx_approval_pending (status, requested_at)
);

-- Leave balances (current balances for each staff member)
CREATE TABLE leave_balances (
    balance_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    leave_type_id INT NOT NULL,
    year YEAR NOT NULL,
    allocated_days DECIMAL(4,1) DEFAULT 0,
    used_days DECIMAL(4,1) DEFAULT 0,
    pending_days DECIMAL(4,1) DEFAULT 0,
    remaining_days DECIMAL(4,1) GENERATED ALWAYS AS (allocated_days - used_days - pending_days) STORED,
    carried_forward DECIMAL(4,1) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id),
    
    UNIQUE KEY unique_staff_leave_year (staff_id, leave_type_id, year),
    INDEX idx_year (year),
    INDEX idx_balances (remaining_days)
);

-- =============================================
-- AUDIT AND TRACKING TABLES
-- =============================================

-- System audit log
CREATE TABLE audit_log (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_by INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (changed_by) REFERENCES staff(staff_id),
    
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_user_time (changed_by, timestamp),
    INDEX idx_timestamp (timestamp)
);

-- Performance tracking (optional - for KPIs)
CREATE TABLE performance_metrics (
    metric_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    metric_type VARCHAR(50) NOT NULL, -- 'attendance', 'productivity', 'quality', etc.
    metric_value DECIMAL(10,2),
    measurement_period_start DATE,
    measurement_period_end DATE,
    notes TEXT,
    recorded_by INT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES staff(staff_id),
    
    INDEX idx_staff_type (staff_id, metric_type),
    INDEX idx_period (measurement_period_start, measurement_period_end)
);

-- =============================================
-- INITIAL DATA SETUP
-- =============================================

-- Insert default staff roles
INSERT INTO staff_roles (role_code, role_name, description, permission_level) VALUES
('SUPERADMIN', 'Super Administrator', 'Full system access', 10),
('HR', 'Human Resources', 'HR management access', 8),
('DML', 'Department Manager Level', 'Department-level management', 6),
('DHS', 'Department Head Supervisor', 'Department supervision', 5),
('STAFF', 'Regular Staff', 'Basic staff access', 2),
('TEMP', 'Temporary Staff', 'Limited temporary access', 1);

-- Insert default staff ranks
INSERT INTO staff_ranks (rank_code, rank_name, description, hierarchy_level) VALUES
('DOC', 'Doctor', 'Medical doctor', 10),
('SPEC', 'Specialist', 'Medical specialist', 9),
('NURSE', 'Nurse', 'Registered nurse', 7),
('TECH', 'Technician', 'Technical staff', 5),
('ADMIN', 'Administrator', 'Administrative staff', 6),
('TEMP', 'Temporary', 'Temporary staff', 2),
('CASUAL', 'Casual', 'Casual staff', 2),
('VOL', 'Volunteer', 'Volunteer staff', 1);

-- Insert default leave types
INSERT INTO leave_types (leave_code, leave_name, description, is_paid, max_days_per_year) VALUES
('ANNUAL', 'Annual Leave', 'Paid annual vacation', TRUE, 30),
('SICK', 'Sick Leave', 'Medical leave', TRUE, 15),
('ABSENT', 'Absent', 'Unplanned absence', FALSE, NULL),
('NOPAY', 'No Pay Leave', 'Unpaid leave', FALSE, NULL),
('EMERG', 'Emergency Leave', 'Emergency situations', TRUE, 5),
('MATERN', 'Maternity Leave', 'Maternity/Paternity leave', TRUE, 90),
('COMP', 'Compensatory Leave', 'Time off in lieu', TRUE, NULL);

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- Current staff overview
CREATE VIEW v_current_staff AS
SELECT 
    s.staff_id,
    s.employee_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    s.email,
    d.department_name,
    f.facility_name,
    sr.role_name,
    srk.rank_name,
    s.employment_status,
    s.hire_date
FROM staff s
LEFT JOIN departments d ON s.current_department_id = d.department_id
LEFT JOIN facilities f ON s.current_facility_id = f.facility_id
LEFT JOIN staff_roles sr ON s.current_role_id = sr.role_id
LEFT JOIN staff_ranks srk ON s.current_rank_id = srk.rank_id
WHERE s.employment_status = 'active';

-- Leave summary view
CREATE VIEW v_leave_summary AS
SELECT 
    s.staff_id,
    s.employee_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    lt.leave_name,
    lb.year,
    lb.allocated_days,
    lb.used_days,
    lb.pending_days,
    lb.remaining_days
FROM staff s
JOIN leave_balances lb ON s.staff_id = lb.staff_id
JOIN leave_types lt ON lb.leave_type_id = lt.leave_type_id
WHERE s.employment_status = 'active'
AND lb.year = YEAR(CURRENT_DATE);

-- Qualification expiry alert view
CREATE VIEW v_qualification_expiry_alerts AS
SELECT 
    s.staff_id,
    s.employee_number,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    q.qualification_name,
    sq.expiry_date,
    DATEDIFF(sq.expiry_date, CURRENT_DATE) AS days_until_expiry
FROM staff s
JOIN staff_qualifications sq ON s.staff_id = sq.staff_id
JOIN qualifications q ON sq.qualification_id = q.qualification_id
WHERE s.employment_status = 'active'
AND sq.expiry_date IS NOT NULL
AND sq.expiry_date <= DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY)
AND sq.verification_status = 'verified'
ORDER BY sq.expiry_date;
