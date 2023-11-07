USE Pruebas
-- Declaración de variables
DECLARE @xmlData XML;
DECLARE @EmpleadosDelXML TABLE (
    tipoDocumentoId INT,
    nombre VARCHAR(64),
    valorTipoDocumento INT,
    puestoId INT,
    departamentoId INT,
    usuario VARCHAR(64),
    clave VARCHAR(64)
);

-- Cargar el archivo XML en la variable @xmlData
SET @xmlData = (
    SELECT *
    FROM OPENROWSET(BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\PruebaInsertarEmpleado.xml', SINGLE_BLOB) AS xmlData
);

-- Obtener la fecha de operación del XML
DECLARE @FechaOperacion DATE = @xmlData.value('(/Operacion/FechaOperacion/@Fecha)[1]', 'DATE');

-- Obtener la fecha actual
DECLARE @FechaActual DATE = GETDATE();

-- Determinar el día de la semana actual (0 = Domingo, 1 = Lunes, ..., 6 = Sábado)
DECLARE @DiaSemanaActual INT = DATEPART(WEEKDAY, @FechaActual);

-- Determinar la fecha de inicio para la próxima semana
DECLARE @FechaInicioProximaSemana DATE;
SET @FechaInicioProximaSemana = DATEADD(DAY, CASE
    WHEN @DiaSemanaActual = 5 THEN 1  -- Si hoy es jueves, permitir inicio al día siguiente
    ELSE CASE
        WHEN @DiaSemanaActual = 7 THEN 2  -- Si hoy es sábado, esperar 2 días
        ELSE 1  -- De lo contrario, esperar 1 día
    END
    END, @FechaActual);

BEGIN TRY
    -- Obtener los datos del empleado actual
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
    FROM @xmlData.nodes('/Operacion/FechaOperacion/NuevosEmpleados/NuevoEmpleado') AS T(Empleado);

    -- Insertar empleados en la próxima semana
    INSERT INTO Empleado (nombre, tipoDocumentoId, valorTipoDocumento, departamentoId, puestoId, usuario, clave)
    SELECT
        nombre, tipoDocumentoId, valorTipoDocumento, departamentoId, puestoId, usuario, clave
    FROM @EmpleadosDelXML;
    
    DELETE FROM @EmpleadosDelXML;
END TRY
BEGIN CATCH
    -- Handle errors here
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con un manejo de errores apropiado
END CATCH;

select * from Empleado

