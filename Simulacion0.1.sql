USE Pruebas
DECLARE @PrimerJueves DATE;
DECLARE @UltimoJueves DATE;
DECLARE @FechaActual DATE
DECLARE @Contador INT;
DECLARE @EsFeriado INT;
DECLARE @FactorMultiplicadorOrdinarias DECIMAL(3, 1);
DECLARE @FactorMultiplicadorDobles DECIMAL(3, 1);

-- Declarar una tabla variable para almacenar las fechas de operación
    DECLARE @FechasOperacion TABLE (
        FechaOperacion DATE
    );
-- Declarar una tabla variable para insertar Empleados
DECLARE @EmpleadosDelXML TABLE (
    tipoDocumentoId INT,
    nombre VARCHAR(64),
    valorTipoDocumento INT,
    puestoId INT,
    departamentoId INT,
    usuario VARCHAR(64),
    clave VARCHAR(64)
);
-- Declaración de tabla variable para empleados que dejan de trabajar
DECLARE @EmpleadosQueDejanDeTrabajar TABLE (
    ValorTipoDocumento INT
);
-- Declaración de tabla para AsociacionEmpleadoDeducciones
DECLARE @AsociarXML TABLE (
    tipoDeduccionId INT,
    valorTipoDocumentoId INT,
    monto MONEY
);
-- Declaración de tabla para almacenar los datos de desasociación del XML
DECLARE @DesasociacionDelXML TABLE (
    IdTipoDeduccion INT,
    ValorTipoDocumento INT
);
-- Declarar una tabla variable para almacenar los datos del XML
    DECLARE @MarcasAsistencia TABLE (
	valorTipoDocumentoId INT,
	horaEntrada DATETIME,
	horaSalida DATETIME
 );
-- Tabla temporal para cargar datos desde el archivo XML
DECLARE @JornadaDelXML TABLE (
    tipoJornadaId INT, 
	valorTipoDocumentoId INT,
	SemanaPlanillaId INT
);

DECLARE @XMLData XML
    SET @xmlData = (
        SELECT *
        FROM OPENROWSET (
            BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\OperacionesXML.xml',
            SINGLE_BLOB
        )
        AS xmlData
    );

-- Insertar fechas de operación en la tabla variable @FechasOperacion
INSERT INTO @FechasOperacion
SELECT FechaOperacion.value('@Fecha', 'DATE') AS Fecha
FROM @xmlData.nodes('/Operacion/FechaOperacion') AS FechaOperacion(FechaOperacion);




-- Inicializar el contador y obtener la primera fecha
SET @Contador = 1
SET @FechaActual = (SELECT TOP 1 FechaOperacion FROM @FechasOperacion ORDER BY FechaOperacion)


-- Ejecutar el procedimiento almacenado y guardar los resultados en las variables
EXEC ObtenerJuevesDelMes @FechaActual, @PrimerJueves OUTPUT, @UltimoJueves OUTPUT;


INSERT INTO MesPlanilla
	(fechaInicio, fechaFin)
VALUES
	(@PrimerJueves, @UltimoJueves)

-- Se debe validar si hoy es jueves, si es jueves se hace el insert de abajo sino no se hace

INSERT INTO SemanaPlanilla
	(fechaInicio, fechaFin, mesPlanillaId)
VALUES(@FechaActual, DATEADD(DAY,7,@FechaActual), (SELECT MAX(id)
		FROM MesPlanilla))


-- Bucle WHILE para iterar sobre las fechas
WHILE @FechaActual IS NOT NULL
BEGIN
PRINT 'Iteracion: ' + CONVERT(VARCHAR, @Contador);
PRINT 'FECHA: ' + CONVERT(VARCHAR, @FechaActual);
PRINT '  '
-- IMPORTANTEEEEE: '/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/'
----------------------------------------------------------------------------
--------------Logica: INSERT EMPLEADO, BORRAR, ASISTENCIA, ETC--------------

BEGIN TRY
    INSERT @EmpleadosDelXML (
        nombre,
        tipoDocumentoId,
        valorTipoDocumento,
        departamentoId,
        puestoId,
        usuario,
        clave
    )
    SELECT
        T.Empleado.value('@Nombre', 'VARCHAR(64)') AS nombre,
        T.Empleado.value('@IdTipoDocumento', 'INT') AS tipoDocumentoId,
        T.Empleado.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumento,
        T.Empleado.value('@IdDepartamento', 'INT') AS departamentoId,
        T.Empleado.value('@IdPuesto', 'INT') AS puestoId,
        T.Empleado.value('@Usuario', 'VARCHAR(64)') AS usuario,
        T.Empleado.value('@Password', 'VARCHAR(64)') AS clave
    FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/NuevosEmpleados/NuevoEmpleado') AS T(Empleado);
    INSERT INTO Empleado (nombre, tipoDocumentoId, valorTipoDocumento, departamentoId, puestoId, usuario, clave)
    SELECT
        nombre, tipoDocumentoId, valorTipoDocumento, departamentoId, puestoId, usuario, clave
    FROM @EmpleadosDelXML;

END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); 
    INSERT INTO dbo.DBErrors (
        UserName,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorProcedure,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES (
        SUSER_SNAME(),
        ERROR_NUMBER(),
        ERROR_STATE(),
        ERROR_SEVERITY(),
        ERROR_LINE(),
        ERROR_PROCEDURE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
END CATCH;
-------Fin Insertar Empleados----------

BEGIN TRY
INSERT INTO @JornadaDelXML (tipoJornadaId, valorTipoDocumentoId, SemanaPlanillaId)
    SELECT
        T.Item.value('@IdTipoJornada', 'INT'),
        T.Item.value('@ValorTipoDocumento', 'INT'),
        (SELECT MAX(id) FROM SemanaPlanilla) 
    FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/JornadasProximaSemana/TipoJornadaProximaSemana') AS T(Item);

    -- Insertar datos de la tabla temporal en la tabla Jornada
    INSERT INTO JornadaProximaSem (tipoJornadaId, SemanaPlanillaId, valorTipoDocumentoId)
    SELECT
        tipoJornadaId,
        SemanaPlanillaId,
		valorTipoDocumentoId
    FROM @JornadaDelXML;
	SELECT * FROM @JornadaDelXML
	SELECT * FROM JornadaProximaSem


END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); 

    INSERT INTO dbo.DBErrors (
        UserName,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorProcedure,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES (
        SUSER_SNAME(),
        ERROR_NUMBER(),
        ERROR_STATE(),
        ERROR_SEVERITY(),
        ERROR_LINE(),
        ERROR_PROCEDURE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
END CATCH;

--------Fin JornadaProximaSem
BEGIN TRY
    INSERT INTO @EmpleadosQueDejanDeTrabajar (ValorTipoDocumento)
    SELECT T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
    FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/EliminarEmpleados/EliminarEmpleado') AS T(Item);

	-- Eliminar empleados de la tabla Jornada basados en 'ValorTipoDocumento'
	Print 'Tenia razon'
	DELETE FROM Jornada
	FROM Jornada
	INNER JOIN @EmpleadosQueDejanDeTrabajar emp ON emp.ValorTipoDocumento = Jornada.valorTipoDocumentoId
	WHERE Jornada.valorTipoDocumentoId = emp.ValorTipoDocumento



END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO dbo.DBErrors (
        UserName,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorProcedure,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES (
        SUSER_SNAME(),
        ERROR_NUMBER(),
        ERROR_STATE(),
        ERROR_SEVERITY(),
        ERROR_LINE(),
        ERROR_PROCEDURE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
END CATCH;
-------Fin eliminar Empleado
BEGIN TRY
INSERT INTO @AsociarXML (tipoDeduccionId, valorTipoDocumentoId, monto)
SELECT
    T.Item.value('@IdTipoDeduccion', 'INT') AS tipoDeduccionId,
    T.Item.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumentoId,
    T.Item.value('@Monto', 'MONEY') AS monto
FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS T(Item);

    -- Realizar la inserción en la tabla DeduccionXempleado 
    INSERT INTO DeduccionXempleado (tipoDeduccionId, valorTipoDocumentoId, monto)
    SELECT tipoDeduccionId, valorTipoDocumentoId, monto
    FROM @AsociarXML;

END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO dbo.DBErrors (
        UserName,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorProcedure,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES (
        SUSER_SNAME(),
        ERROR_NUMBER(),
        ERROR_STATE(),
        ERROR_SEVERITY(),
        ERROR_LINE(),
        ERROR_PROCEDURE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
END CATCH;

--------------Fin AsociacionEmpleadoDeducciones
BEGIN TRY
-- Insertar valores del XML en la tabla @DesasociacionDelXML
INSERT INTO @DesasociacionDelXML (IdTipoDeduccion, ValorTipoDocumento)
SELECT
    T.Item.value('@IdTipoDeduccion', 'INT') AS IdTipoDeduccion,
    T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS T(Item);

DELETE Deduc
FROM DeduccionXempleado Deduc
INNER JOIN @DesasociacionDelXML Desasocia ON Deduc.valorTipoDocumentoId = Desasocia.ValorTipoDocumento

END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); 
    INSERT INTO dbo.DBErrors (
        UserName,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorProcedure,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES (
        SUSER_SNAME(),
        ERROR_NUMBER(),
        ERROR_STATE(),
        ERROR_SEVERITY(),
        ERROR_LINE(),
        ERROR_PROCEDURE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
END CATCH;
------------Fin Desasociar
BEGIN TRY
    BEGIN TRANSACTION;

    -- Insertar datos del XML en la tabla variable @MarcasAsistencia
    INSERT INTO @MarcasAsistencia
        (
            valorTipoDocumentoId,
            horaEntrada,
            horaSalida
        )
    SELECT
        T.Item.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumentoId,
        T.Item.value('@HoraEntrada', 'DATETIME') AS horaEntrada,
        T.Item.value('@HoraSalida', 'DATETIME') AS horaSalida
    FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/MarcasAsistencia/MarcaDeAsistencia') AS T(Item);

    -- Insertar datos en la tabla MarcasAsistencia
    INSERT INTO MarcasAsistencia
        (valorTipoDocumentoId, horaEntrada, horaSalida)
    SELECT *
    FROM @MarcasAsistencia;
----------------Mov Horas---------------------------
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

	-- Calcular el factor de multiplicacion

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
	SET @FactorMultiplicadorDobles = 0;
END



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
    WHERE MA.horaEntrada >= @FechaActual;

-------------Movimiento Planilla----------------
INSERT INTO MovimientoPlanilla
    (fecha, monto, nuevoSalarioBruto, movHorasId, planillaSemXEmp)
SELECT
    @FechaActual,
    (montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
    COALESCE(
        (SELECT PS.salarioBruto
         FROM PlanillaSemXEmp PS
         INNER JOIN PlanillaMesXEmp PM ON PM.id = PS.planillaMesXempId
         WHERE PS.id = (SELECT TOP 1 id FROM PlanillaSemXEmp ORDER BY id DESC)
        ), 0.00
    ) + (montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
    MovHoras.id,
    COALESCE(
        (SELECT TOP 1 PS.id
         FROM PlanillaSemXEmp PS
         INNER JOIN PlanillaMesXEmp PM ON PM.id = PS.planillaMesXempId
         WHERE PM.valorTipoDocumentoId = MA.valorTipoDocumentoId
         AND semanaPlanillaId = (SELECT MAX(id) FROM SemanaPlanilla)
         ORDER BY PS.id DESC
        ), 0 -- proporciona un valor predeterminado si la subconsulta devuelve NULL
    )
FROM MovHoras
    INNER JOIN MarcasAsistencia MA ON MA.id = MovHoras.marcasAsistenciaId
WHERE CAST(MA.horaEntrada AS date) = @FechaActual;

UPDATE PlanillaSemXEmp
SET salarioBruto = PS.salarioBruto + MOV.monto
FROM PlanillaSemXEmp PS
INNER JOIN PlanillaMesXEmp PM ON PS.planillaMesXempId = PM.id
INNER JOIN MovimientoPlanilla MOV ON MOV.planillaSemXEmp = PS.id
where MOV.fecha = @FechaActual

---------------------------------------------------------------------------
-----------------------------Validaciones----------------------------------
IF (DATEPART(WEEKDAY, CONVERT(DATE, @FechaActual, 105))) = 5
BEGIN
	DELETE FROM Jornada
	------------Jornadas------------
    INSERT INTO Jornada (tipoJornadaId, SemanaPlanillaId, valorTipoDocumentoId)
    SELECT
        tipoJornadaId,
        SemanaPlanillaId,
		valorTipoDocumentoId
    FROM JornadaProximaSem;
	DELETE FROM JornadaProximaSem


-- Se debe validar si hoy es jueves, si es jueves se hace el insert de abajo sino no se hace

	IF @FechaActual != '2023-07-06'
	BEGIN
		PRINT 'QUIERO HACER UPDATE'
		UPDATE PlanillaSemXEmp 
		SET salarioNeto = salarioBruto - totalDeducciones
		WHERE semanaPlanillaId = (SELECT MAX(id) FROM SemanaPlanilla)
	END

    IF @FechaActual = CAST(@UltimoJueves AS DATE) OR (SELECT COUNT(id) from MesPlanilla) = 0
    BEGIN
		PRINT 'MUCHACHOS, SE NOS ACABO EL MES'
		BEGIN TRY
		UPDATE PlanillaMesXEmp
		SET SalarioBruto = PS.salarioNeto
		FROM PlanillaMesXEmp PM
		INNER JOIN PlanillaSemXEmp PS ON PS.planillaMesXempId = PM.id
		END TRY
		BEGIN CATCH
			PRINT ERROR_MESSAGE();
		END CATCH
		DECLARE @FechaTemporal DATE 
		IF @FechaActual = '2023-07-06'
		BEGIN
			SET @FechaTemporal = @FechaActual;
		END ELSE
		BEGIN
			SET @FechaTemporal = DATEADD(MONTH, 1, @FechaActual);
		END

        EXEC ObtenerJuevesDelMes @FechaTemporal, @PrimerJueves OUTPUT, @UltimoJueves OUTPUT;
		INSERT INTO MesPlanilla
		(fechaInicio, fechaFin)
		VALUES
			(@FechaActual, @UltimoJueves)

        -- Crear nueva planilla para el próximo mes
		INSERT INTO PlanillaMesXEmp
			(salarioBruto, totalDeducciones, mesPlanillaId, valorTipoDocumentoId)
		SELECT 0.0, 0.0, (SELECT MAX(id)
			FROM MesPlanilla), valorTipoDocumento
		FROM Empleado
		

    END

	
		INSERT INTO SemanaPlanilla
		(fechaInicio, fechaFin, mesPlanillaId)
		VALUES(@FechaActual, DATEADD(DAY,7,@FechaActual), (SELECT MAX(id)
		FROM MesPlanilla))

		PRINT '2. aquiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii'
		
		INSERT INTO PlanillaMesXEmp (salarioBruto, totalDeducciones, mesPlanillaId, valorTipoDocumentoId)
		SELECT 0.0, 0.0, (SELECT MAX(id) FROM MesPlanilla), valorTipoDocumento
		FROM Empleado e
		WHERE NOT EXISTS (
			SELECT 1
			FROM PlanillaMesXEmp p
			WHERE p.valorTipoDocumentoId = e.valorTipoDocumento
		);
		
		
		INSERT INTO PlanillaSemXEmp
			(salarioNeto, semanaPlanillaId, planillaMesXempId,
			salarioBruto, totalDeducciones)
		SELECT 0.0, (SELECT MAX(id)
			FROM SemanaPlanilla),
			PM.id,
			0.0, 0.0
		FROM Jornada emp
		INNER JOIN PlanillaMesXEmp PM ON PM.valorTipoDocumentoId = emp.valorTipoDocumentoId  
		AND PM.mesPlanillaId = (SELECT MAX(id) FROM MesPlanilla)
	END



	COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
	PRINT ERROR_MESSAGE();
	    INSERT INTO dbo.DBErrors (
        UserName,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorProcedure,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES (
        SUSER_SNAME(),
        ERROR_NUMBER(),
        ERROR_STATE(),
        ERROR_SEVERITY(),
        ERROR_LINE(),
        ERROR_PROCEDURE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
END CATCH


----------------------------------------------------------------------------
----------------------Limpieza de variables tablas--------------------------
DELETE FROM @EmpleadosDelXML;
DELETE FROM @EmpleadosQueDejanDeTrabajar;
DELETE FROM @AsociarXML;
DELETE FROM @DesasociacionDelXML;
DELETE FROM @MarcasAsistencia;
DELETE FROM @JornadaDelXML ;
----------------------------------------------------------------------------
----------------No tocar: Aqui se selecciona la siguiente fecha-------------
    SET @Contador = @Contador + 1
    SET @FechaActual = (SELECT FechaOperacion FROM @FechasOperacion ORDER BY FechaOperacion OFFSET @Contador - 1 ROWS FETCH NEXT 1 ROWS ONLY)
----------------------------------------------------------------------------

END;

