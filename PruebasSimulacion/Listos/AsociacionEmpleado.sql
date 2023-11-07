USE Pruebas;

-- Declaración de variables
DECLARE @xmlData XML;

-- Load the XML content into the @xmlData variable
SET @xmlData = (
    SELECT *
    FROM OPENROWSET(BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\pruebasAsociacionEmpleado.xml', SINGLE_BLOB) AS xmlData
);

-- Declaración de tabla para almacenar los datos del XML
DECLARE @DeduccionesDelXML TABLE (
    tipoDeduccionId INT,
    valorTipoDocumentoId INT,
    monto MONEY
);

-- Insertar valores del XML en la tabla @DeduccionesDelXML
INSERT INTO @DeduccionesDelXML (tipoDeduccionId, valorTipoDocumentoId, monto)
SELECT
    T.Item.value('@IdTipoDeduccion', 'INT') AS tipoDeduccionId,
    T.Item.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumentoId,
    T.Item.value('@Monto', 'MONEY') AS monto
FROM @xmlData.nodes('/Operacion/FechaOperacion/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS T(Item);

BEGIN TRY
    -- Calcular la fecha del próximo inicio de semana
    DECLARE @ProximoInicioDeSemana DATE;
    SET @ProximoInicioDeSemana = DATEADD(DAY, 7 - DATEPART(WEEKDAY, GETDATE()), GETDATE());

    -- Realizar la inserción en la tabla DeduccionXempleado si la fecha de registro es a partir del próximo inicio de semana
    INSERT INTO DeduccionXempleado (tipoDeduccionId, valorTipoDocumentoId, monto, fechaDeRegistro)
    SELECT tipoDeduccionId, valorTipoDocumentoId, monto, @ProximoInicioDeSemana
    FROM @DeduccionesDelXML;

END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con un manejo de errores adecuado
END CATCH;

