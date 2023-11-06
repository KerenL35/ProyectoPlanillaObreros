USE Pruebas
-- Declaración de variables
DECLARE @xmlData XML;
DECLARE @NuevoEmpleadoNombre VARCHAR(64);
DECLARE @IdTipoDocumento INT;
DECLARE @ValorTipoDocumento INT;
DECLARE @IdDepartamento INT;
DECLARE @IdPuesto INT;
DECLARE @Usuario VARCHAR(64);
DECLARE @Password VARCHAR(64);


SET @xmlData = (
        SELECT *
        FROM OPENROWSET(BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\PruebasSimulacion\PruebaInsertarEmpleado.xml', SINGLE_BLOB) AS xmlData
    );

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
SET NOCOUNT ON;

BEGIN TRY

        -- Obtener los datos del empleado actual
		INSERT @EmpleadosDelXML (
					nombre
					, tipoDocumentoId
					, valorTipoDocumento
					, departamentoId
					, puestoId
					, usuario
					, clave
				)

			SELECT
				T.Empleado.value('@Nombre', 'VARCHAR(64)') AS nombre,
				T.Empleado.value('@IdTipoDocumento', 'INT') AS tipoDocumentoId,
				T.Empleado.value('@ValorTipoDocumento', 'INT') AS valorTipoDocumento,
				T.Empleado.value('@IdDepartamento', 'INT') AS departamentoId,
				T.Empleado.value('@IdPuesto', 'INT') AS puestoId,
				T.Empleado.value('@Usuario', 'VARCHAR(64)') AS usuario,
				T.Empleado.value('@Password', 'VARCHAR(64)') AS clave
			FROM @xmlData.nodes('/Operacion/NuevosEmpleados/NuevoEmpleado') AS T(Empleado)



            -- Insertar datos del empleado en la tabla Empleado
		INSERT INTO Empleado SELECT * FROM @EmpleadosDelXML
		
		DELETE FROM @EmpleadosDelXML
        


END TRY
BEGIN CATCH
    -- Handle errors here
    PRINT ERROR_MESSAGE(); -- Puedes reemplazar esto con un manejo de errores apropiado
END CATCH;

