-- Usar la base de datos 'Pruebas'
USE Pruebas;

-- Declaración de variables
DECLARE @xmlData XML;

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

    -- Declarar una tabla variable para almacenar los datos del XML
    DECLARE @MarcasAsistencia TABLE (
        valorTipoDocumentoId INT,
        horaEntrada DATETIME,
        horaSalida DATETIME
    );

    -- Insertar datos del XML en la tabla variable @MarcasAsistencia
    INSERT INTO @MarcasAsistencia (
        valorTipoDocumentoId, 
        horaEntrada, 
        horaSalida)
    SELECT
        T.Item.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumentoId,
        T.Item.value('@HoraEntrada', 'DATETIME') AS horaEntrada,
        T.Item.value('@HoraSalida', 'DATETIME') AS horaSalida
    FROM @xmlData.nodes('/Operacion/FechaOperacion/MarcasAsistencia/MarcaDeAsistencia') AS T(Item);

    -- Mostrar los datos insertados en la tabla @MarcasAsistencia
    SELECT * FROM @MarcasAsistencia;

    -- Insertar datos en la tabla MarcasAsistencia
    INSERT INTO MarcasAsistencia (valorTipoDocumentoId, horaEntrada, horaSalida)
    SELECT * FROM @MarcasAsistencia;

	-- Declaración de variable para la fecha actual
	DECLARE @FechaActual DATE;

	SELECT @FechaActual = FechaOperacion.value('@Fecha', 'DATE')
	FROM @xmlData.nodes('/Operacion/FechaOperacion') AS FechaOperacion(FechaOperacion);

	-- Verificar si el día actual es feriado
	DECLARE @EsFeriado INT;

	IF EXISTS (SELECT 1 FROM Feriado WHERE fecha = @FechaActual)
	BEGIN
		SET @EsFeriado = 1;
	END
	ELSE
	BEGIN
		SET @EsFeriado = 0;
	END

	-- Calcular el factor de multiplicación
	DECLARE @FactorMultiplicadorOrdinarias DECIMAL(3, 1);
	DECLARE @FactorMultiplicadorDobles DECIMAL(3, 1);

	IF DATEPART(WEEKDAY, CONVERT(DATE, @FechaActual, 105)) = 1 OR @EsFeriado = 1
	BEGIN 
		SET @FactorMultiplicadorOrdinarias = 0; -- Domingo o feriado
		SET @FactorMultiplicadorDobles = 2; -- Otros días
	END

	ELSE
	BEGIN 
		SET @FactorMultiplicadorOrdinarias = 1.5; -- Otros días
		SET @FactorMultiplicadorDobles = 0; 
	END

	-- Calcular las horas trabajadas ordinarias y horas extras
	INSERT INTO MovHoras (marcasAsistenciaId, montoHorasOrdinaria, montoHorasExtras, montoHorasExtrasDoble)
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

	



	INSERT INTO MovimientoPlanilla(fecha, monto, nuevoSalarioBruto, movHorasId)
	SELECT 
	@FechaActual,
	(montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
	COALESCE((SELECT
		salarioBruto
		FROM SemanaPlanilla
		WHERE valorTipoDocumentoId = MA.valorTipoDocumentoId 
		AND MA.horaEntrada >= fechaInicio
		AND MA.horaSalida <= fechaFin),0.00) + (montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
	MovHoras.id
	FROM MovHoras
	INNER JOIN MarcasAsistencia MA ON MA.id = MovHoras.marcasAsistenciaId
	WHERE CAST(MA.horaEntrada AS date) = @FechaActual



END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con el manejo de errores adecuado
END CATCH;

SELECT * FROM MovHoras
SELECT * FROM MovimientoPlanilla

