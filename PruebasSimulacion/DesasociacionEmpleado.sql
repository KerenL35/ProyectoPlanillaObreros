USE Pruebas;

-- Declaración de variables
DECLARE @xmlData XML;

-- Load the new XML content into the @xmlData variable
SET @xmlData = (
    SELECT *
    FROM OPENROWSET(BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\nuevoXML.xml', SINGLE_BLOB) AS xmlData
);

-- Declaración de tabla para almacenar los datos de desasociación del XML
DECLARE @DesasociacionDelXML TABLE (
    IdTipoDeduccion INT,
    ValorTipoDocumento INT
);

-- Insertar valores del XML en la tabla @DesasociacionDelXML
INSERT INTO @DesasociacionDelXML (IdTipoDeduccion, ValorTipoDocumento)
SELECT
    T.Item.value('@IdTipoDeduccion', 'INT') AS IdTipoDeduccion,
    T.Item.value('@ValorTipoDocumento', 'INT') AS ValorTipoDocumento
FROM @xmlData.nodes('/Operacion/FechaOperacion/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS T(Item);

BEGIN TRY
    -- Calcular la fecha del próximo inicio de semana
    DECLARE @ProximoInicioDeSemana DATE;
    SET @ProximoInicioDeSemana = DATEADD(DAY, 7 - DATEPART(WEEKDAY, GETDATE()), GETDATE());
    
    -- Ejecutar la desasociación
    DELETE DX
    FROM DeduccionXempleado DX
    JOIN @DesasociacionDelXML Desasociacion ON DX.tipoDeduccionId = Desasociacion.IdTipoDeduccion
        AND DX.valorTipoDocumentoId = Desasociacion.ValorTipoDocumento
    WHERE DATEADD(DAY, 7 - DATEPART(WEEKDAY, GETDATE()), DX.FechaDeRegistro) >= @ProximoInicioDeSemana;
    
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con un manejo de errores adecuado
END CATCH;
