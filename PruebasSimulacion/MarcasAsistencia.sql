USE Pruebas;

-- Declaración de variables
DECLARE @xmlData XML;

-- Cargar datos XML desde el archivo
SET NOCOUNT ON;
BEGIN TRY
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
    FROM @xmlData.nodes('/Operacion/MarcasAsistencia/MarcaDeAsistencia') AS T(Item);

    -- Mostrar los datos insertados en la tabla @MarcasAsistencia
    SELECT * FROM @MarcasAsistencia;

    -- Insertar datos en la tabla MarcasAsistencia
    INSERT INTO MarcasAsistencia (valorTipoDocumentoId, horaEntrada, horaSalida)
    SELECT * FROM @MarcasAsistencia;

-- Calcular las horas trabajadas extras normales y generar movimientos
DECLARE @SalarioPorHoraExtras DECIMAL(10, 2); -- Debes establecer el salario por hora extra del empleado

INSERT INTO MovHoras (marcasAsistenciaId, horasExtras, monto)
SELECT
    MA.id,
    CASE
        WHEN DATEDIFF(HOUR, MA.horaSalida, MA.horaEntrada) > 7.5 THEN DATEDIFF(HOUR, MA.horaSalida, MA.horaEntrada) - 7.5
        ELSE 0
    END AS horasExtras,
    CASE
        WHEN DATEPART(WEEKDAY, MA.horaSalida) IN (1, 7) THEN 1.5 -- Domingo o sábado
        -- Agregar aquí la lógica para verificar si la fecha es feriado y establecer el factor multiplicador apropiado.
        ELSE 1.5 -- Por defecto, se utiliza 1.5
    END * 
    (CASE
        WHEN DATEDIFF(HOUR, MA.horaSalida, MA.horaEntrada) > 7.5 THEN DATEDIFF(HOUR, MA.horaSalida, MA.horaEntrada) - 7.5
        ELSE 0
    END) * @SalarioPorHoraExtras AS monto
FROM MarcasAsistencia AS MA
JOIN Empleado AS E ON E.valorTipoDocumento = MA.valorTipoDocumentoId
WHERE DATEDIFF(HOUR, MA.horaSalida, MA.horaEntrada) > 7.5; -- Solo se pagan horas extras (más de 7.5 horas)


    -- Mostrar los datos insertados en la tabla MovHoras
    SELECT * FROM MovHoras;

END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con el manejo de errores adecuado
END CATCH;
