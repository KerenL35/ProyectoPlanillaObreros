USE Pruebas;

-- Declaración de variables
DECLARE @xmlDataDelete XML;
DECLARE @FechaOperacion DATE; -- Agrega una variable para la fecha de operación

SET @xmlDataDelete = (
    SELECT *
    FROM OPENROWSET(BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\pruebas.xml', SINGLE_BLOB) AS xmlData
);

-- Obtener la fecha de operación del XML
SET @FechaOperacion = @xmlDataDelete.value('(/Operacion/FechaOperacion/@Fecha)[1]', 'DATE');

-- Declaración de tabla variable para empleados que dejan de trabajar
DECLARE @EmpleadosQueDejanDeTrabajar TABLE (
    ValorTipoDocumento INT
);

-- Insertar valores en la tabla variable desde el archivo XML
INSERT INTO @EmpleadosQueDejanDeTrabajar (ValorTipoDocumento)
SELECT T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
FROM @xmlDataDelete.nodes('/Operacion/FechaOperacion/EliminarEmpleados/EliminarEmpleado') AS T(Item);


-- Cargar el archivo XML en la variable @xmlDataDelete
SET NOCOUNT ON;

BEGIN TRY
    -- Recorrer los elementos <EliminarEmpleado> en el XML
    INSERT INTO @EmpleadosQueDejanDeTrabajar (ValorTipoDocumento)
    SELECT T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
    FROM @xmlDataDelete.nodes('/Operacion/EliminarEmpleados/EliminarEmpleado') AS T(Item);

    -- Eliminar empleados basados en 'ValorTipoDocumento' y la fecha de operación
    DELETE E
    FROM [Pruebas].[dbo].[Empleado] AS E
    INNER JOIN @EmpleadosQueDejanDeTrabajar AS T
        ON E.[valorTipoDocumento] = T.ValorTipoDocumento;

END TRY
BEGIN CATCH
    -- Handle errors here
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con un manejo de errores apropiado
END CATCH;
 

