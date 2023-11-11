SELECT * FROM Empleado
USE Pruebas
DELETE FROM PlanillaSemXEmp
DBCC CHECKIDENT ('PlanillaSemXEmp', RESEED, 0);
DELETE FROM PlanillaMesXEmp
DBCC CHECKIDENT ('PlanillaMesXEmp', RESEED, 0);
DELETE FROM SemanaPlanilla
DBCC CHECKIDENT ('SemanaPlanilla', RESEED, 0);
DELETE FROM MesPlanilla
DBCC CHECKIDENT ('MesPlanilla', RESEED, 0);
delete from MovimientoPlanilla
DBCC CHECKIDENT ('MovimientoPlanilla', RESEED, 0);
delete from MovHoras
DBCC CHECKIDENT ('MovHoras', RESEED, 0);
delete from MarcasAsistencia
DBCC CHECKIDENT ('MarcasAsistencia', RESEED, 0);



select * from MarcasAsistencia

 
go
DROP VIEW IF EXISTS vw_SalarioBruto
go
CREATE VIEW vw_SalarioBruto AS
SELECT  MA.valorTipoDocumentoId identi, SUM(montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble) AS Bruto FROM MovHoras MH
INNER JOIN MarcasAsistencia MA ON MA.id = MH.id
GROUP BY (MA.valorTipoDocumentoId)
go

SELECT Bruto FROM vw_SalarioBruto WHERE identi = 314052787

	SELECT 
	'2023-07-07',
	(montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
	COALESCE((SELECT
		salarioBruto
		FROM SemanaPlanilla
		WHERE valorTipoDocumentoId = MA.valorTipoDocumentoId 
		AND MA.horaEntrada >= fechaInicio
		AND MA.horaSalida <= fechaFin),0.00),
	MovHoras.id
	FROM MovHoras
	INNER JOIN MarcasAsistencia MA ON MA.id = MovHoras.marcasAsistenciaId
	WHERE CAST(MA.horaEntrada AS date) = '2023-07-07'

		SELECT 
	'2023-07-07',
	(montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
	
	MovHoras.id
	FROM MovHoras
	INNER JOIN MarcasAsistencia MA ON MA.id = MovHoras.marcasAsistenciaId
	WHERE CAST(MA.horaEntrada AS date) = '2023-07-07'

	SELECT COALESCE(salarioBruto,0.00) FROM SemanaPlanilla

	
