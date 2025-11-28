IF DB_ID('GimnasioDB') IS NULL
    CREATE DATABASE GimnasioDB;
GO

USE GimnasioDB;
GO

CREATE SCHEMA gym;
GO

CREATE TABLE gym.Socio (
    SocioID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100),
    Apellido NVARCHAR(100),
    FechaNacimiento DATE,
    Telefono VARCHAR(20),
    Email VARCHAR(150),
    FechaAlta DATETIME DEFAULT GETDATE(),
    Estado VARCHAR(20) DEFAULT 'Activo'
);

CREATE TABLE gym.Entrenador (
    EntrenadorID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100),
    Apellido NVARCHAR(100),
    Especialidad NVARCHAR(100),
    Telefono VARCHAR(20),
    Email VARCHAR(150)
);

CREATE TABLE gym.Membresia (
    MembresiaID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100),
    DuracionDias INT,
    Precio DECIMAL(10,2)
);

CREATE TABLE gym.Clase (
    ClaseID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100),
    Descripcion NVARCHAR(250),
    DuracionMin INT
);

CREATE TABLE gym.HorarioClase (
    HorarioID INT IDENTITY(1,1) PRIMARY KEY,
    ClaseID INT,
    EntrenadorID INT,
    FechaHora DATETIME,
    Capacidad INT DEFAULT 20,
    Sala NVARCHAR(50),
    FOREIGN KEY (ClaseID) REFERENCES gym.Clase(ClaseID),
    FOREIGN KEY (EntrenadorID) REFERENCES gym.Entrenador(EntrenadorID)
);

CREATE TABLE gym.Reserva (
    ReservaID INT IDENTITY(1,1) PRIMARY KEY,
    HorarioID INT,
    SocioID INT,
    FechaReserva DATETIME DEFAULT GETDATE(),
    Estado VARCHAR(20) DEFAULT 'Confirmada',
    FOREIGN KEY (HorarioID) REFERENCES gym.HorarioClase(HorarioID),
    FOREIGN KEY (SocioID) REFERENCES gym.Socio(SocioID)
);

CREATE TABLE gym.Pago (
    PagoID INT IDENTITY(1,1) PRIMARY KEY,
    SocioID INT,
    FechaPago DATETIME DEFAULT GETDATE(),
    Monto DECIMAL(10,2),
    Metodo VARCHAR(50),
    MembresiaID INT NULL,
    ReservaID INT NULL,
    FOREIGN KEY (SocioID) REFERENCES gym.Socio(SocioID),
    FOREIGN KEY (MembresiaID) REFERENCES gym.Membresia(MembresiaID),
    FOREIGN KEY (ReservaID) REFERENCES gym.Reserva(ReservaID)
);

CREATE TABLE gym.Area (
    AreaID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100),
    Descripcion NVARCHAR(250)
);

CREATE TABLE gym.Equipo (
    EquipoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(150),
    AreaID INT,
    Cantidad INT DEFAULT 1,
    Estado VARCHAR(50) DEFAULT 'Operativo',
    FOREIGN KEY (AreaID) REFERENCES gym.Area(AreaID)
);

CREATE NONCLUSTERED INDEX IX_Socio_Nombre ON gym.Socio (Apellido, Nombre);
CREATE NONCLUSTERED INDEX IX_Horario_Fecha ON gym.HorarioClase (FechaHora);
CREATE NONCLUSTERED INDEX IX_Reserva ON gym.Reserva (HorarioID, SocioID);
CREATE NONCLUSTERED INDEX IX_Pago_Fecha ON gym.Pago (FechaPago);

ALTER TABLE gym.Reserva
ADD CONSTRAINT UQ_Reserva UNIQUE (HorarioID, SocioID);
GO

CREATE PROCEDURE gym.sp_CrearReserva
    @HorarioID INT,
    @SocioID INT,
    @Resultado INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM gym.Reserva WHERE HorarioID = @HorarioID AND SocioID = @SocioID)
    BEGIN SET @Resultado = 2; RETURN; END

    DECLARE @Cap INT = (SELECT Capacidad FROM gym.HorarioClase WHERE HorarioID = @HorarioID);
    DECLARE @Usados INT = (SELECT COUNT(*) FROM gym.Reserva WHERE HorarioID = @HorarioID AND Estado = 'Confirmada');

    IF @Usados >= @Cap
    BEGIN SET @Resultado = 1; RETURN; END

    INSERT INTO gym.Reserva (HorarioID, SocioID) VALUES (@HorarioID, @SocioID);
    SET @Resultado = 0;
END;
GO

CREATE LOGIN usuarioGimnasio WITH PASSWORD = 'Gimnasio123$';

USE GimnasioDB;
CREATE USER usuarioGimnasio FOR LOGIN usuarioGimnasio;

CREATE ROLE rol_admin;
GRANT CONTROL ON SCHEMA::gym TO rol_admin;

CREATE ROLE rol_operativo;

GRANT SELECT, INSERT, UPDATE ON gym.Socio TO rol_operativo;
GRANT SELECT, INSERT, UPDATE ON gym.Reserva TO rol_operativo;
GRANT SELECT, INSERT ON gym.Pago TO rol_operativo;

CREATE ROLE rol_lectura;
GRANT SELECT ON SCHEMA::gym TO rol_lectura;




INSERT INTO gym.Socio (Nombre, Apellido, FechaNacimiento, Telefono, Email) VALUES
('Carlos','Alfaro','1995-04-12','70123456','carlos@mail.com'),
('Emely','Aguilar','1988-11-02','70123457','emely@mail.com'),
('Luis','Martinez','1992-06-20','70123458','luis@mail.com'),
('Ana','Rodriguez','2000-01-15','70123459','ana@mail.com'),
('Jose','Ramirez','1985-09-09','70123460','jose@mail.com'),
('Sofia','Vargas','1999-12-30','70123461','sofia@mail.com');

INSERT INTO gym.Entrenador (Nombre, Apellido, Especialidad, Telefono, Email) VALUES
('Juan','Perez','Cardio','70123500','juan@mail.com'),
('Laura','Suarez','Yoga','70123501','laura@mail.com'),
('Miguel','Hernandez','Fuerza','70123502','miguel@mail.com'),
('Isabel','Lopez','Pilates','70123503','isabel@mail.com'),
('Raul','Gomez','Spinning','70123504','raul@mail.com'),
('Elena','Ortega','Crossfit','70123505','elena@mail.com');

INSERT INTO gym.Membresia (Nombre, DuracionDias, Precio) VALUES
('Mensual',30,30),
('Trimestral',90,80),
('Semestral',180,150),
('Anual',365,280),
('Dia',1,5),
('Prueba',7,0);

INSERT INTO gym.Clase (Nombre, Descripcion, DuracionMin) VALUES
('Yoga','Clase de yoga',60),
('Spinning','Bicicleta',45),
('Pilates','Flexibilidad',50),
('Crossfit','Funcional',60),
('Zumba','Baile',50),
('Funcional','Circuitos',45);

INSERT INTO gym.Area (Nombre, Descripcion) VALUES
('Cardio','Maquinas cardio'),
('Pesas','Pesas y maquinas'),
('SalaClases','Sala principal'),
('Piscina','Zona piscina'),
('Recepcion','Front desk'),
('Vestidores','Area de lockers');

INSERT INTO gym.Equipo (Nombre, AreaID, Cantidad, Estado) VALUES
('Cinta correr',1,6,'Operativo'),
('Bicicleta estatica',1,8,'Operativo'),
('Mancuernas',2,20,'Operativo'),
('Colchonetas',3,30,'Operativo'),
('Remo',1,4,'Operativo'),
('Kettlebells',2,15,'Operativo');

INSERT INTO gym.HorarioClase (ClaseID, EntrenadorID, FechaHora, Capacidad, Sala) VALUES
(1,2,DATEADD(day,1,GETDATE()),15,'Sala A'),
(2,5,DATEADD(day,1,GETDATE()),20,'Sala B'),
(3,4,DATEADD(day,1,GETDATE()),12,'Sala A'),
(4,6,DATEADD(day,2,GETDATE()),18,'Sala C'),
(5,1,DATEADD(day,2,GETDATE()),25,'Sala B'),
(6,3,DATEADD(day,3,GETDATE()),20,'Sala C');

INSERT INTO gym.Reserva (HorarioID, SocioID, Estado) VALUES
(1,1,'Confirmada'),
(1,2,'Confirmada'),
(2,3,'Confirmada'),
(3,4,'Confirmada'),
(4,5,'Confirmada'),
(5,6,'Confirmada');

INSERT INTO gym.Pago (SocioID, FechaPago, Monto, Metodo, MembresiaID, ReservaID) VALUES
(1,GETDATE(),30,'Tarjeta',1,NULL),
(2,GETDATE(),80,'Efectivo',2,NULL),
(3,GETDATE(),5,'Efectivo',5,NULL),
(4,GETDATE(),150,'Tarjeta',3,NULL),
(5,GETDATE(),0,'Prueba',6,NULL),
(6,GETDATE(),30,'Tarjeta',1,NULL);


SELECT h.HorarioID, c.Nombre AS Clase, h.FechaHora, h.Capacidad,
       COALESCE(r.ReservasActivas,0) AS ReservasActivas,
       h.Capacidad - COALESCE(r.ReservasActivas,0) AS Disponibles
FROM gym.HorarioClase h
JOIN gym.Clase c ON h.ClaseID = c.ClaseID
LEFT JOIN (
    SELECT HorarioID, COUNT(1) AS ReservasActivas
    FROM gym.Reserva WHERE Estado = 'Confirmada'
    GROUP BY HorarioID
) r ON h.HorarioID = r.HorarioID
WHERE h.FechaHora >= GETDATE()
ORDER BY h.FechaHora;


SELECT FORMAT(FechaPago,'yyyy-MM') AS Mes, SUM(Monto) AS Ingresos
FROM gym.Pago
WHERE FechaPago >= DATEADD(MONTH, -6, GETDATE())
GROUP BY FORMAT(FechaPago,'yyyy-MM')
ORDER BY Mes;


SELECT HorarioID, ReservaID, SocioID, FechaReserva,
       ROW_NUMBER() OVER (PARTITION BY HorarioID ORDER BY FechaReserva ASC) AS PosicionEnLista
FROM gym.Reserva;


SELECT SocioID, Nombre, Apellido, Telefono, Email
FROM gym.Socio
WHERE Apellido LIKE 'A%';


-- FULL backup (hacerlo semanalmente)
BACKUP DATABASE GimnasioDB
TO DISK = 'C:\Backups\GimnasioDB_FULL.bak'
WITH INIT, COMPRESSION, STATS = 5;
GO

-- DIFERENCIAL (diario entre fulls)
BACKUP DATABASE GimnasioDB
TO DISK = 'C:\Backups\GimnasioDB_DIFF.bak'
WITH DIFFERENTIAL, COMPRESSION, STATS = 5;
GO

-- BACKUP LOG (cada N horas, si la BD está en FULL recovery)
BACKUP LOG GimnasioDB
TO DISK = 'C:\Backups\GimnasioDB_LOG.trn'
WITH COMPRESSION, STATS = 5;
GO

-- Restaurar FULL
RESTORE DATABASE GimnasioDB
FROM DISK = 'C:\Backups\GimnasioDB_FULL.bak'
WITH NORECOVERY;
GO

-- Restaurar DIF
RESTORE DATABASE GimnasioDB
FROM DISK = 'C:\Backups\GimnasioDB_DIFF.bak'
WITH NORECOVERY;
GO

-- Restaurar LOG
RESTORE LOG GimnasioDB
FROM DISK = 'C:\Backups\GimnasioDB_LOG.trn'
WITH RECOVERY;
GO


BULK INSERT gym.Socio
FROM 'C:\data\socio.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

EXEC sp_addrolemember 'rol_lectura', 'usuarioGimnasio';

EXEC sp_addrolemember 'rol_operativo', 'usuarioGimnasio';

