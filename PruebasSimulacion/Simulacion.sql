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
DECLARE @DeduccionesDelXML TABLE (
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
            BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\OperacionesV2.xml',
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
-----------------Fin Insertar Empleados------------------------------------
BEGIN TRY
    INSERT INTO @EmpleadosQueDejanDeTrabajar (ValorTipoDocumento)
    SELECT T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
    FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/EliminarEmpleados/EliminarEmpleado') AS T(Item);

	-- Eliminar empleados de la tabla dbo.EmpleadosXSemana basados en 'ValorTipoDocumento'
	DELETE Jornada
	FROM Jornada
	INNER JOIN @EmpleadosQueDejanDeTrabajar
		ON Jornada.valorTipoDocumentoId = @EmpleadosQueDejanDeTrabajar.ValorTipoDocumento;

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
----------------------Fin eliminar empleado---------------------------------
BEGIN TRY
-- Insertar valores del XML en la tabla @DeduccionesDelXML
INSERT INTO @DeduccionesDelXML (tipoDeduccionId, valorTipoDocumentoId, monto)
SELECT
    T.Item.value('@IdTipoDeduccion', 'INT') AS tipoDeduccionId,
    T.Item.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumentoId,
    T.Item.value('@Monto', 'MONEY') AS monto
FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS T(Item);

    -- Realizar la inserción en la tabla DeduccionXempleado 
    INSERT INTO DeduccionXempleado (tipoDeduccionId, valorTipoDocumentoId, monto)
    SELECT tipoDeduccionId, valorTipoDocumentoId, monto
    FROM @DeduccionesDelXML;

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
--------------------Fin AsociacionEmpleadoDeducciones-----------------------
BEGIN TRY
-- Insertar valores del XML en la tabla @DesasociacionDelXML
INSERT INTO @DesasociacionDelXML (IdTipoDeduccion, ValorTipoDocumento)
SELECT
    T.Item.value('@IdTipoDeduccion', 'INT') AS IdTipoDeduccion,
    T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS T(Item);

    -- Ejecutar la desasociación
	DELETE DeduccionXempleado
	FROM DeduccionXempleado
	JOIN @DesasociacionDelXML ON DeduccionXempleado.tipoDeduccionId = @DesasociacionDelXML.IdTipoDeduccion
		AND DeduccionXempleado.valorTipoDocumentoId = @DesasociacionDelXML.ValorTipoDocumento;
   
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
--------------------Fin Desasociacion---------------------------------------
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

    COMMIT TRANSACTION;
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
END CATCH;
-------------------Fin MarcasAsistencia------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

    -- Procesar los datos de Jornada y almacenarlos en la tabla temporal
    INSERT INTO @JornadaDelXML (tipoJornadaId, valorTipoDocumentoId, SemanaPlanillaId)
    SELECT
        T.Item.value('@IdTipoJornada', 'INT'),
        T.Item.value('@ValorTipoDocumento', 'INT'),
        (SELECT MAX(id) FROM SemanaPlanilla) 
    FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/JornadasProximaSemana/TipoJornadaProximaSemana') AS T(Item);

    -- Insertar datos de la tabla temporal en la tabla Jornada
    INSERT INTO Jornada (tipoJornadaId, valorTipoDocumentoId, SemanaPlanillaId)
    SELECT
        tipoJornadaId,
        valorTipoDocumentoId,
        SemanaPlanillaId
    FROM @JornadaDelXML;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- Si hay un error, revertir la transacción
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE(); 

    -- Registrar el error en la tabla dbo.DBErrors
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
----------------------Fin JornadasProximaSemana-----------------------------
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO PlanillaSemXEmp
        (salarioNeto, semanaPlanillaId, planillaMesXempId, salarioBruto, totalDeducciones)
    SELECT
        0.0,
        (SELECT MAX(id) FROM SemanaPlanilla),
        (SELECT MAX(id) FROM PlanillaMesXEmp WHERE valorTipoDocumentoId = emp.valorTipoDocumento),
        0.0,
        0.0
    FROM Empleado emp;

    COMMIT TRANSACTION;
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
END CATCH;
------------------------Fin PlanillaSemXEmp--------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

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

    COMMIT TRANSACTION;
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
END CATCH;
----------------------------Fin MovHoras-----------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

    -- Insertar datos en la tabla MovimientoPlanilla
    INSERT INTO MovimientoPlanilla
        (fecha, monto, nuevoSalarioBruto, movHorasId, planillaSemXEmp)
    SELECT
        @FechaActual,
        (montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
        COALESCE(
            (SELECT PS.salarioBruto
             FROM PlanillaSemXEmp PS
             INNER JOIN PlanillaMesXEmp PM ON PM.id = PS.id
             WHERE PS.id = (SELECT MAX(id) FROM PlanillaSemXEmp)
            ), 0.00
        ) + (montoHorasOrdinaria + montoHorasExtras + montoHorasExtrasDoble),
        MovHoras.id,
        (SELECT PS.id
         FROM PlanillaSemXEmp PS
         INNER JOIN PlanillaMesXEmp PM ON PM.id = PS.id
         WHERE PM.valorTipoDocumentoId = MA.valorTipoDocumentoId
        )
    FROM MovHoras
        INNER JOIN MarcasAsistencia MA ON MA.id = MovHoras.marcasAsistenciaId
    WHERE CAST(MA.horaEntrada AS date) = @FechaActual;

    COMMIT TRANSACTION;
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
END CATCH;
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Validaciones------------------------------------

------------
	-- Verificar si el dia actual es feriado

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


----------------------------------------------------------------------------
SELECT
	T.Item.value('@Nombre', 'VARCHAR(120)') AS Nombre
FROM @xmlData.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/NuevosEmpleados/NuevoEmpleado') AS T(Item);

----------------------------------------------------------------------------
----------------------Limpieza de variables tablas--------------------------
DELETE FROM @EmpleadosDelXML;
DELETE FROM @EmpleadosQueDejanDeTrabajar;
DELETE FROM @DeduccionesDelXML;
DELETE FROM @DesasociacionDelXML;
DELETE FROM @MarcasAsistencia;
DELETE FROM @JornadaDelXML ;
----------------------------------------------------------------------------
----------------No tocar: Aqui se selecciona la siguiente fecha-------------
    SET @Contador = @Contador + 1
    SET @FechaActual = (SELECT FechaOperacion FROM @FechasOperacion ORDER BY FechaOperacion OFFSET @Contador - 1 ROWS FETCH NEXT 1 ROWS ONLY)
	PRINT 'Iteracion: ' + CONVERT(VARCHAR, @Contador);
	PRINT 'FECHA: ' + CONVERT(VARCHAR, @FechaActual);
	PRINT '  '
----------------------------------------------------------------------------
END