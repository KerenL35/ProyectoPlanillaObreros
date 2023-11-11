-- Usar la base de datos 'Pruebas'
USE Pruebas;

BEGIN TRANSACTION;

-- Declaracion de variables
DECLARE @xmlData XML;
DECLARE @FechaPrimerJueves DATE;
DECLARE @FechaUltimoJueves DATE;


-- Cargar datos XML desde el archivo
SET NOCOUNT ON;
BEGIN TRY
    -- Leer datos XML desde un archivo
    SET @xmlData = (
        SELECT *
FROM OPENROWSET (
            BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\MarcaAsistencia.xml',
            SINGLE_BLOB
        )
        AS xmlData
    );	



-- Obtén el primer día del mes
DECLARE @PrimerDiaDelMes DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FechaEntrada), 0);

-- Calcula el día de la semana del primer día del mes (0 = Domingo, 6 = Sábado)
DECLARE @DiaSemana INT = DATEPART(WEEKDAY, @PrimerDiaDelMes);

-- Calcula el número de días para llegar al primer jueves (1 = Lunes, 2 = Martes, etc.)
DECLARE @DiasHastaJueves INT = CASE
    WHEN @DiaSemana <= 5 THEN 5 - @DiaSemana
    ELSE 12 - @DiaSemana
END;

-- Calcula la fecha del primer jueves
----
SET @FechaPrimerJueves = DATEADD(DAY, @DiasHastaJueves, @PrimerDiaDelMes);

-- Calcula la fecha del último día del mes
DECLARE @UltimoDiaDelMes DATE = EOMONTH(@FechaEntrada);

-- Calcula el número de días para llegar al último jueves (0 = Jueves, 1 = Viernes, etc.)
DECLARE @DiasHastaUltimoJueves INT = (DATEDIFF(DAY, @FechaPrimerJueves, @UltimoDiaDelMes) / 7) * 7;

-- Calcula la fecha del último jueves
SET @FechaUltimoJueves = DATEADD(DAY, @DiasHastaUltimoJueves, @FechaPrimerJueves);



    -- Declarar una tabla variable para almacenar los datos del XML
    DECLARE @MarcasAsistencia TABLE (
	valorTipoDocumentoId INT,
	horaEntrada DATETIME,
	horaSalida DATETIME
    );



    -- Insertar datos del XML en la tabla variable @MarcasAsistencia
    INSERT INTO @MarcasAsistencia
	(
	valorTipoDocumentoId,
	horaEntrada,
	horaSalida)
SELECT
	T.Item.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumentoId,
	T.Item.value('@HoraEntrada', 'DATETIME') AS horaEntrada,
	T.Item.value('@HoraSalida', 'DATETIME') AS horaSalida
FROM @xmlData.nodes('/Operacion/FechaOperacion/MarcasAsistencia/MarcaDeAsistencia') AS T(Item);

    -- Mostrar los datos insertados en la tabla @MarcasAsistencia
    SELECT *
FROM @MarcasAsistencia;

    -- Insertar datos en la tabla MarcasAsistencia
    INSERT INTO MarcasAsistencia
	(valorTipoDocumentoId, horaEntrada, horaSalida)
SELECT *
FROM @MarcasAsistencia;

	-- Declaraci�n de variable para la fecha actual
	DECLARE @FechaActual DATE;

	SELECT @FechaActual = FechaOperacion.value('@Fecha', 'DATE')
FROM @xmlData.nodes('/Operacion/FechaOperacion') AS FechaOperacion(FechaOperacion);


INSERT INTO MesPlanilla
	(fechaInicio, fechaFin)
VALUES
	(@FechaPrimerJueves, @FechaUltimoJueves)

-- Se debe validar si hoy es jueves, si es jueves se hace el insert de abajo sino no se hace

INSERT INTO SemanaPlanilla
	(fechaInicio, fechaFin, mesPlanillaId)
VALUES(@FechaActual, DATEADD(DAY,7,@FechaActual), (SELECT MAX(id)
		FROM MesPlanilla))

	-- Verificar si el d�a actual es feriado
	DECLARE @EsFeriado INT;

	IF EXISTS (SELECT 1
FROM Feriado
WHERE fecha = @FechaActual)
	BEGIN
	SET @EsFeriado = 1;
END
	ELSE
	BEGIN
	SET @EsFeriado = 0;
END

	-- Calcular el factor de multiplicaci�n
	DECLARE @FactorMultiplicadorOrdinarias DECIMAL(3, 1);
	DECLARE @FactorMultiplicadorDobles DECIMAL(3, 1);

	IF DATEPART(WEEKDAY, CONVERT(DATE, @FechaActual, 105)) = 1 OR @EsFeriado = 1
	BEGIN
	SET @FactorMultiplicadorOrdinarias = 0;
	-- Domingo o feriado
	SET @FactorMultiplicadorDobles = 2;
-- Otros d�as
END

	ELSE
	BEGIN
	SET @FactorMultiplicadorOrdinarias = 1.5;
	-- Otros d�as
	SET @FactorMultiplicadorDobles = 0;
END


INSERT INTO PlanillaMesXEmp
	(salarioBruto, totalDeducciones, mesPlanillaId, valorTipoDocumentoId)
SELECT 0.0, 0.0, (SELECT MAX(id)
	FROM MesPlanilla), valorTipoDocumento
FROM Empleado

INSERT INTO PlanillaSemXEmp
	(salarioNeto, semanaPlanillaId, planillaMesXempId,
	salarioBruto, totalDeducciones)
SELECT 0.0, (SELECT MAX(id)
	FROM SemanaPlanilla),
	(SELECT MAX(id)
	FROM PlanillaMesXEmp
	WHERE valorTipoDocumentoId = emp.valorTipoDocumento),
	0.0, 0.0
FROM Empleado emp

	-- Calcular las horas trabajadas ordinarias y horas extras
	INSERT INTO MovHoras
	(marcasAsistenciaId, montoHorasOrdinaria, montoHorasExtras, montoHorasExtrasDoble)
SELECT
	MA.id,
	CASE
			-- Calcular horas trabajadas ordinarias
			WHEN DATEDIFF(HOUR, MA.horaEntrada, MA.horaSalida) <= 8 THEN DATEDIFF(HOUR, MA.horaEntrada, MA.horaSalida) * Puesto.salarioXhora
			ELSE 8 * Puesto.salarioXhora
		END AS montoHorasOrdinaria,
	CASE
			-- Calcular horas extras normales
			WHEN DATEDIFF(HOUR, MA.horaEntrada, MA.horaSalida) <= 8 THEN 0
			ELSE (DATEDIFF(HOUR, MA.horaEntrada, MA.horaSalida) - 8) * Puesto.salarioXhora * @FactorMultiplicadorOrdinarias
		END AS montoHorasExtras,
	CASE
			-- Calcular horas extras dobles
			WHEN DATEDIFF(HOUR, MA.horaEntrada, MA.horaSalida) > 8 THEN
				(DATEDIFF(HOUR, MA.horaEntrada, MA.horaSalida) - 8) * @FactorMultiplicadorDobles * Puesto.salarioXhora
			ELSE 0
		END AS montoHorasExtrasDoble
FROM MarcasAsistencia MA
	INNER JOIN Empleado ON Empleado.valorTipoDocumento = MA.valorTipoDocumentoId
	INNER JOIN Puesto ON Empleado.puestoId = Puesto.id
WHERE MA.horaEntrada >= @FechaActual


	INSERT INTO MovimientoPlanilla
	(fecha, monto, nuevoSalarioBruto, movHorasId, planillaSemXEmp)
SELECT
	@FechaActual,
	(montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
	COALESCE((SELECT PS.salarioBruto FROM PlanillaSemXEmp PS
			 INNER JOIN PlanillaMesXEmp PM ON PM.id = PS.id
			 WHERE PS.id = (SELECT MAX(id) FROM PlanillaSemXEmp) ),0.00) + (montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
	MovHoras.id,
	(SELECT PS.id
	FROM PlanillaSemXEmp PS
		INNER JOIN PlanillaMesXEmp PM ON PM.id = PS.id
	WHERE PM.valorTipoDocumentoId = MA.valorTipoDocumentoId
			  )

FROM MovHoras
	INNER JOIN MarcasAsistencia MA ON MA.id = MovHoras.marcasAsistenciaId
WHERE CAST(MA.horaEntrada AS date) = @FechaActual

	COMMIT;
END TRY
BEGIN CATCH
    -- ROLLBACK en caso de error
    ROLLBACK;
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con el manejo de errores adecuado
END CATCH;

SELECT *
FROM MovHoras
SELECT *
FROM MovimientoPlanilla

