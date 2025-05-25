-- Staff Auditing and Tracking System Database Schema
-- Designed for high performance, scalability, and maintainability
-- Normalized to 3NF with optimized indexing strategy

-- =============================================
-- ORGANIZATIONAL STRUCTURE TABLES
-- =============================================

-- Master departments table
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_code VARCHAR(10) NOT NULL UNIQUE,
    department_name VARCHAR(100) NOT NULL,
    parent_department_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_department_id) REFERENCES departments(department_id),
    INDEX idx_dept_parent (parent_department_id),
    INDEX idx_dept_active (is_active),
    INDEX idx_dept_code (department_code)
);

-- Facilities under departments
CREATE TABLE facilities (
    facility_id INT PRIMARY KEY AUTO_INCREMENT,
    facility_code VARCHAR(15) NOT NULL UNIQUE,
    facility_name VARCHAR(150) NOT NULL,
    department_id INT NOT NULL,
    address TEXT,
    facility_type ENUM('main', 'branch', 'satellite', 'temporary') DEFAULT 'branch',
    capacity INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE,
    INDEX idx_facility_dept (department_id),
    INDEX idx_facility_active (is_active),
    INDEX idx_facility_type (facility_type),
    INDEX idx_facility_code (facility_code)
);

-- =============================================
-- ROLE AND PERMISSION MANAGEMENT
-- =============================================

-- System roles definition
CREATE TABLE system_roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permission_level TINYINT NOT NULL DEFAULT 1, -- 1-10 scale
    is_admin_role BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_role_permission (permission_level),
    INDEX idx_role_admin (is_admin_role),
    INDEX idx_role_active (is_active)
);

-- Staff ranks/positions
CREATE TABLE staff_ranks (
    rank_id INT PRIMARY KEY AUTO_INCREMENT,
    rank_name VARCHAR(50) NOT NULL UNIQUE,
    rank_category ENUM('doctor', 'nurse', 'admin', 'support', 'temporary', 'casual', 'volunteer') NOT NULL,
    rank_level TINYINT NOT NULL DEFAULT 1, -- Hierarchy level within category
    base_salary_range_min DECIMAL(10,2) DEFAULT 0,
    base_salary_range_max DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_rank_category (rank_category),
    INDEX idx_rank_level (rank_level),
    INDEX idx_rank_active (is_active)
);

-- Permission modules for granular access control
CREATE TABLE permission_modules (
    module_id INT PRIMARY KEY AUTO_INCREMENT,
    module_name VARCHAR(50) NOT NULL UNIQUE,
    module_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_module_active (is_active)
);

-- Role-based permissions matrix
CREATE TABLE role_permissions (
    permission_id INT PRIMARY KEY AUTO_INCREMENT,
    role_id INT NOT NULL,
    module_id INT NOT NULL,
    can_read BOOLEAN DEFAULT FALSE,
    can_write BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE,
    can_approve BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (role_id) REFERENCES system_roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (module_id) REFERENCES permission_modules(module_id) ON DELETE CASCADE,
    UNIQUE KEY uk_role_module (role_id, module_id),
    INDEX idx_perm_role (role_id),
    INDEX idx_perm_module (module_id)
);

-- =============================================
-- STAFF MANAGEMENT CORE TABLES
-- =============================================

-- Main staff registry
CREATE TABLE staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    hire_date DATE NOT NULL,
    termination_date DATE NULL,
    employment_status ENUM('active', 'inactive', 'terminated', 'suspended') DEFAULT 'active',
    department_id INT NOT NULL,
    facility_id INT NOT NULL,
    role_id INT NOT NULL,
    rank_id INT NOT NULL,
    supervisor_id INT NULL, -- Self-referencing for hierarchy
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (facility_id) REFERENCES facilities(facility_id),
    FOREIGN KEY (role_id) REFERENCES system_roles(role_id),
    FOREIGN KEY (rank_id) REFERENCES staff_ranks(rank_id),
    FOREIGN KEY (supervisor_id) REFERENCES staff(staff_id),
    
    INDEX idx_staff_emp_num (employee_number),
    INDEX idx_staff_email (email),
    INDEX idx_staff_dept (department_id),
    INDEX idx_staff_facility (facility_id),
    INDEX idx_staff_role (role_id),
    INDEX idx_staff_rank (rank_id),
    INDEX idx_staff_supervisor (supervisor_id),
    INDEX idx_staff_status (employment_status),
    INDEX idx_staff_hire_date (hire_date),
    INDEX idx_staff_name (last_name, first_name)
);

-- Staff assignment history for tracking department/facility changes
CREATE TABLE staff_assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    department_id INT NOT NULL,
    facility_id INT NOT NULL,
    role_id INT NOT NULL,
    rank_id INT NOT NULL,
    assignment_start_date DATE NOT NULL,
    assignment_end_date DATE NULL,
    assignment_reason ENUM('hire', 'transfer', 'promotion', 'demotion', 'temporary') NOT NULL,
    is_current BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (facility_id) REFERENCES facilities(facility_id),
    FOREIGN KEY (role_id) REFERENCES system_roles(role_id),
    FOREIGN KEY (rank_id) REFERENCES staff_ranks(rank_id),
    FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    
    INDEX idx_assign_staff (staff_id),
    INDEX idx_assign_current (is_current),
    INDEX idx_assign_dates (assignment_start_date, assignment_end_date),
    INDEX idx_assign_dept (department_id),
    INDEX idx_assign_facility (facility_id)
);

-- =============================================
-- QUALIFICATIONS AND TRAINING
-- =============================================

-- Qualification types (education, certifications, licenses)
CREATE TABLE qualification_types (
    qualification_type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    type_category ENUM('education', 'certification', 'license', 'training') NOT NULL,
    is_mandatory BOOLEAN DEFAULT FALSE,
    validity_period_months INT NULL, -- NULL for permanent qualifications
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_qual_type_category (type_category),
    INDEX idx_qual_type_mandatory (is_mandatory),
    INDEX idx_qual_type_active (is_active)
);

-- Staff qualifications
CREATE TABLE staff_qualifications (
    qualification_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    qualification_type_id INT NOT NULL,
    qualification_name VARCHAR(100) NOT NULL,
    issuing_authority VARCHAR(100),
    issue_date DATE,
    expiry_date DATE NULL,
    verification_status ENUM('pending', 'verified', 'rejected', 'expired') DEFAULT 'pending',
    document_path VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (qualification_type_id) REFERENCES qualification_types(qualification_type_id),
    
    INDEX idx_qual_staff (staff_id),
    INDEX idx_qual_type (qualification_type_id),
    INDEX idx_qual_status (verification_status),
    INDEX idx_qual_expiry (expiry_date),
    UNIQUE KEY uk_staff_qualification (staff_id, qualification_type_id, qualification_name)
);

-- =============================================
-- LEAVE MANAGEMENT SYSTEM
-- =============================================

-- Leave categories and policies
CREATE TABLE leave_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    category_code VARCHAR(10) NOT NULL UNIQUE,
    is_paid BOOLEAN DEFAULT TRUE,
    requires_approval BOOLEAN DEFAULT TRUE,
    max_days_per_year INT DEFAULT 0, -- 0 for unlimited
    min_notice_days INT DEFAULT 0,
    max_consecutive_days INT DEFAULT 0, -- 0 for unlimited
    can_carry_forward BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_leave_cat_code (category_code),
    INDEX idx_leave_cat_active (is_active)
);

-- Staff leave entitlements
CREATE TABLE staff_leave_entitlements (
    entitlement_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    category_id INT NOT NULL,
    year YEAR NOT NULL,
    allocated_days DECIMAL(5,2) DEFAULT 0,
    used_days DECIMAL(5,2) DEFAULT 0,
    pending_days DECIMAL(5,2) DEFAULT 0,
    carried_forward_days DECIMAL(5,2) DEFAULT 0,
    remaining_days DECIMAL(5,2) GENERATED ALWAYS AS (allocated_days + carried_forward_days - used_days - pending_days) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES leave_categories(category_id),
    
    UNIQUE KEY uk_staff_leave_year (staff_id, category_id, year),
    INDEX idx_entitle_staff (staff_id),
    INDEX idx_entitle_category (category_id),
    INDEX idx_entitle_year (year)
);

-- Leave applications and records
CREATE TABLE leave_applications (
    application_id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    category_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days DECIMAL(5,2) NOT NULL,
    application_date DATE NOT NULL,
    reason TEXT,
    status ENUM('pending', 'approved', 'rejected', 'cancelled') DEFAULT 'pending',
    approved_by INT NULL,
    approved_date DATETIME NULL,
    rejection_reason TEXT NULL,
    emergency_contact_during_leave VARCHAR(100),
    handover_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES leave_categories(category_id),
    FOREIGN KEY (approved_by) REFERENCES staff(staff_id),
    
    INDEX idx_leave_app_staff (staff_id),
    INDEX idx_leave_app_category (category_id),
    INDEX idx_leave_app_status (status),
    INDEX idx_leave_app_dates (start_date, end_date),
    INDEX idx_leave_app_approver (approved_by),
    INDEX idx_leave_app_date (application_date)
);

-- =============================================
-- AUDIT AND TRACKING TABLES
-- =============================================

-- Comprehensive audit log for all critical operations
CREATE TABLE audit_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    changed_by INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (changed_by) REFERENCES staff(staff_id),
    
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_record (record_id),
    INDEX idx_audit_action (action_type),
    INDEX idx_audit_user (changed_by),
    INDEX idx_audit_timestamp (timestamp),
    INDEX idx_audit_table_record (table_name, record_id)
);

-- User sessions for security tracking
CREATE TABLE user_sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    staff_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    logout_time TIMESTAMP NULL,
    session_status ENUM('active', 'expired', 'logged_out') DEFAULT 'active',
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    
    INDEX idx_session_staff (staff_id),
    INDEX idx_session_status (session_status),
    INDEX idx_session_activity (last_activity)
);

-- =============================================
-- REPORTING AND ANALYTICS VIEWS
-- =============================================

-- Comprehensive staff view for reporting
CREATE VIEW v_staff_details AS
SELECT 
    s.staff_id,
    s.employee_number,
    CONCAT(s.first_name, ' ', COALESCE(s.middle_name, ''), ' ', s.last_name) as full_name,
    s.email,
    s.phone,
    s.employment_status,
    s.hire_date,
    d.department_name,
    f.facility_name,
    sr.role_name,
    sr.permission_level,
    sk.rank_name,
    sk.rank_category,
    CONCAT(sup.first_name, ' ', sup.last_name) as supervisor_name,
    s.created_at,
    s.updated_at
FROM staff s
JOIN departments d ON s.department_id = d.department_id
JOIN facilities f ON s.facility_id = f.facility_id
JOIN system_roles sr ON s.role_id = sr.role_id
JOIN staff_ranks sk ON s.rank_id = sk.rank_id
LEFT JOIN staff sup ON s.supervisor_id = sup.staff_id;

-- Leave balance summary view
CREATE VIEW v_staff_leave_summary AS
SELECT 
    s.staff_id,
    s.employee_number,
    CONCAT(s.first_name, ' ', s.last_name) as staff_name,
    lc.category_name,
    sle.year,
    sle.allocated_days,
    sle.used_days,
    sle.pending_days,
    sle.remaining_days,
    sle.carried_forward_days
FROM staff s
JOIN staff_leave_entitlements sle ON s.staff_id = sle.staff_id
JOIN leave_categories lc ON sle.category_id = lc.category_id
WHERE s.employment_status = 'active';

-- =============================================
-- INITIAL DATA SETUP
-- =============================================

-- Insert default system roles
INSERT INTO system_roles (role_name, role_description, permission_level, is_admin_role) VALUES
('superadmin', 'System Super Administrator', 10, TRUE),
('hr_admin', 'Human Resources Administrator', 8, TRUE),
('dml_admin', 'Data Management Administrator', 7, TRUE),
('dhs_admin', 'Department Head Administrator', 6, TRUE),
('facility_admin', 'Facility Administrator', 5, TRUE),
('supervisor', 'Department Supervisor', 4, FALSE),
('staff_user', 'Regular Staff User', 2, FALSE);

-- Insert default staff ranks
INSERT INTO staff_ranks (rank_name, rank_category, rank_level) VALUES
('Chief Medical Officer', 'doctor', 10),
('Senior Consultant', 'doctor', 9),
('Consultant', 'doctor', 8),
('Resident Doctor', 'doctor', 6),
('Head Nurse', 'nurse', 8),
('Senior Nurse', 'nurse', 6),
('Staff Nurse', 'nurse', 4),
('Department Head', 'admin', 9),
('Assistant Manager', 'admin', 6),
('Administrative Officer', 'admin', 4),
('Senior Support Staff', 'support', 5),
('Support Staff', 'support', 3),
('Temporary Staff', 'temporary', 2),
('Casual Worker', 'casual', 1),
('Volunteer', 'volunteer', 1);

-- Insert default leave categories
INSERT INTO leave_categories (category_name, category_code, is_paid, max_days_per_year, min_notice_days) VALUES
('Annual Leave', 'AL', TRUE, 21, 7),
('Sick Leave', 'SL', TRUE, 10, 0),
('Maternity Leave', 'ML', TRUE, 90, 30),
('Paternity Leave', 'PL', TRUE, 14, 14),
('Compassionate Leave', 'CL', TRUE, 5, 0),
('Study Leave', 'STL', TRUE, 10, 30),
('Leave Without Pay', 'LWP', FALSE, 30, 14),
('Emergency Leave', 'EL', TRUE, 3, 0);

-- Insert default permission modules
INSERT INTO permission_modules (module_name, module_description) VALUES
('staff_management', 'Staff creation, modification, and termination'),
('leave_management', 'Leave applications and approvals'),
('reporting', 'System reports and analytics'),
('audit_logs', 'Audit trail and system logs'),
('department_management', 'Department and facility management'),
('qualification_management', 'Staff qualifications and certifications'),
('system_administration', 'System configuration and user management');

-- =============================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- =============================================

-- Composite indexes for common query patterns
CREATE INDEX idx_staff_dept_facility_active ON staff (department_id, facility_id, employment_status);
CREATE INDEX idx_leave_staff_year_category ON staff_leave_entitlements (staff_id, year, category_id);
CREATE INDEX idx_leave_app_staff_status_dates ON leave_applications (staff_id, status, start_date, end_date);
CREATE INDEX idx_audit_table_timestamp ON audit_logs (table_name, timestamp);
CREATE INDEX idx_qual_staff_expiry ON staff_qualifications (staff_id, expiry_date);
