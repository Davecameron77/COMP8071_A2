USE COMP8071;

-- Customer table
IF OBJECT_ID(N'dbo.Customer', N'U') IS NOT NULL
    DROP TABLE dbo.Customer;
GO
CREATE TABLE Customer(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	BirthDate DATE,
	Picture VARBINARY(MAX),
	Gender CHAR(1)
);
-- ROLAP Customer table
IF OBJECT_ID(N'dbo.Rolap_Customer_Dim', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_Customer_Dim;
GO
CREATE TABLE Rolap_Customer_Dim(
	ID INT NOT NULL PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	BirthDate DATE,
	Picture VARBINARY(MAX),
	Gender CHAR(1)
);
GO

-- Employee table
IF OBJECT_ID(N'dbo.Employee', N'U') IS NOT NULL
    DROP TABLE dbo.Employee;
GO
CREATE TABLE Employee(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	ManagerID INT,
	JobTitle VARCHAR(128),
	CertifiedFor VARCHAR(256),
	StartDate DATE,
	Salary MONEY
);
-- Rolap Employee table
IF OBJECT_ID(N'dbo.Rolap_Employee_Dim', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_Employee_Dim;
GO
CREATE TABLE Rolap_Employee_Dim(
	ID INT NOT NULL PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	ManagerID INT,
	JobTitle VARCHAR(128),
	CertifiedFor VARCHAR(256),
	StartDate DATE,
	Salary MONEY
);

-- ServiceType table
IF OBJECT_ID(N'dbo.ServiceType', N'U') IS NOT NULL
    DROP TABLE dbo.ServiceType;
GO
CREATE TABLE ServiceType(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	CertificationReqts VARCHAR(256),
	Rate MONEY
);
-- ROLAP ServiceType table
IF OBJECT_ID(N'dbo.Rolap_ServiceType_Dim', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_ServiceType_Dim;
GO
CREATE TABLE Rolap_ServiceType_Dim(
	ID INT NOT NULL PRIMARY KEY,
	Name VARCHAR(128),
	CertificationReqts VARCHAR(256),
	Rate MONEY
);

IF(NOT EXISTS(SELECT 1 FROM dbo.ServiceType))
	-- Insert into ServiceType
	INSERT INTO ServiceType VALUES ('Nursing', 'Nursing', 25);
	INSERT INTO ServiceType VALUES ('Medical', 'Medical', 45);
	INSERT INTO ServiceType VALUES ('Cleaning', 'Custodial', 15);
	INSERT INTO ServiceType VALUES ('Food Prep', 'Foodsafe', 20);
	INSERT INTO ServiceType VALUES ('Administration', NULL, 22);
	GO
;

-- CustomerService table
IF OBJECT_ID(N'dbo.CustomerService', N'U') IS NOT NULL
    DROP TABLE dbo.CustomerService;
GO
CREATE TABLE CustomerService(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	CustomerID INT NOT NULL,
	ServiceTypeID INT NOT NULL,
	ExpectedDuration DECIMAL
);
-- CustomerService Table
IF OBJECT_ID(N'dbo.CustomerServiceSchedule', N'U') IS NOT NULL
    DROP TABLE dbo.CustomerServiceSchedule;
GO
CREATE TABLE CustomerServiceSchedule(
	ID INT NOT NULL PRIMARY KEY,
	CustomerID INT NOT NULL,
	ServiceTypeID INT NOT NULL,
	EmployeeID INT NOT NULL,
	StartDateTime DATETIME NOT NULL,
	ActualDuration DECIMAL,
	Status CHAR(1)
);
-- ROLAP CustomerServiceSchedule Facts
IF OBJECT_ID(N'dbo.Rolap_CustomerServiceSchedule_Facts', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_CustomerServiceSchedule_Facts;
GO
CREATE TABLE Rolap_CustomerServiceSchedule_Facts(
	ID INT NOT NULL PRIMARY KEY,
	CustomerID INT NOT NULL,
	ServiceTypeID INT NOT NULL,
	EmployeeID INT,
	StartDateTime DATETIME,
	ActualDuration DECIMAL,
	Status CHAR(1)
);
GO

-- Create Triggers
CREATE TRIGGER Tr_CustomerAdded ON Customer
AFTER INSERT
AS 
BEGIN
	INSERT INTO dbo.Rolap_Customer_Dim SELECT * FROM INSERTED ins;
	PRINT 'Copied a customer'
END
GO

CREATE TRIGGER Tr_EmployeeAdded ON Employee
AFTER INSERT
AS 
BEGIN
	INSERT INTO dbo.Rolap_Employee_Dim SELECT * FROM INSERTED ins;
	PRINT 'Copied an employee'
END
GO

CREATE TRIGGER Tr_ServiceAdded ON ServiceType
AFTER INSERT
AS BEGIN
	INSERT INTO dbo.Rolap_ServiceType_Dim SELECT * FROM INSERTED ins;
	PRINT 'Copied a service'
END
GO

CREATE TRIGGER Tr_CustomerServiceAdded ON CustomerService
AFTER INSERT
AS BEGIN
	INSERT INTO dbo.Rolap_CustomerServiceSchedule_Facts (ID, CustomerID, ServiceTypeID, ActualDuration)
	SELECT ID, CustomerID, ServiceTypeID, ExpectedDuration FROM INSERTED ins;
END
GO

CREATE TRIGGER Tr_CustomerServiceScheduleAdded ON CustomerServiceSchedule
AFTER INSERT
AS BEGIN
DECLARE 
	@ID INT,
	@EmployeeID INT,
	@StartDateTime Date,
	@ActualDuration Decimal(18,0),
	@Status Char(1);

	SELECT @ID = ins.ID FROM INSERTED ins;
	SELECT @EmployeeID = ins.EmployeeID FROM INSERTED ins;
	SELECT @StartDateTime = ins.StartDateTime FROM INSERTED ins;
	SELECT @ActualDuration = ins.ActualDuration FROM INSERTED ins;
	SELECT @Status = ins.Status FROM INSERTED ins;
	
	UPDATE [Rolap_CustomerServiceSchedule_Facts]
	SET EmployeeID = @EmployeeID,
		StartDateTime = @StartDateTime,
		ActualDuration = @ActualDuration,
		Status = @Status
	WHERE ID = @ID
END
GO
