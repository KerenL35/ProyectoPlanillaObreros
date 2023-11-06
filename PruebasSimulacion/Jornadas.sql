USE Pruebas;

-- Declaración de variables
DECLARE @xmlData XML;

-- Cargar el archivo XML en la variable @xmlData
SET NOCOUNT ON; -- Desactivar el recuento de filas afectadas
BEGIN TRY
    SET @xmlData = (
        SELECT *
        FROM OPENROWSET (
            BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\TipoJornada.xml',
            SINGLE_BLOB
        ) AS xmlData
    );

-- Tabla temporal para cargar datos desde el archivo XML
DECLARE @JornadaDelXML TABLE (
    tipoJornadaId INT, 
    valorTipoDocumentoId INT,
	SemanaPlanillaId DATE
);

    -- Procesar los datos de Jornada y almacenarlos en la tabla temporal
    INSERT INTO @JornadaDelXML (tipoJornadaId, SemanaPlanillaId, valorTipoDocumentoId)
    SELECT
        T.Item.value('@IdTipoJornada', 'INT'),
        CAST(T.Item.value('@SemanaPlanillaId', 'DATE') AS DATE), 
        T.Item.value('@ValorTipoDocumento', 'INT')
    FROM @xmlData.nodes('/Operacion/FechaOperacion/JornadasProximaSemana/JornadaProximaSemana') AS T(Item);

select * from @JornadaDelXML

END TRY
BEGIN CATCH
    -- Insertar datos de la tabla temporal en la tabla Jornada
    INSERT INTO [dbo].[Jornada] (tipoJornadaId, SemanaPlanillaId, valorTipoDocumentoId)
    SELECT
        tipoJornadaId,
        valorTipoDocumentoId,
		SemanaPlanillaId
    PRINT ERROR_MESSAGE(); -- Puedes agregar aquí tu lógica de manejo de errores
END CATCH;

SELECT * FROM Jornada;
