-- Declaración de variables
DECLARE @xmlData XML;
DECLARE @FechaOperacion DATE;
DECLARE @NuevoEmpleadoNombre VARCHAR(50);
DECLARE @IdTipoDocumento INT;
DECLARE @ValorTipoDocumento INT;
DECLARE @IdDepartamento INT;
DECLARE @IdPuesto INT;
DECLARE @Usuario VARCHAR(16);
DECLARE @Password VARCHAR(16);

-- Cargar el archivo XML en la variable @xmlData
SET @xmlData = (
    SELECT *
    FROM OPENROWSET(BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\OperacionesV2.xml', SINGLE_BLOB) AS xmlData
);

-- Obtener la fecha de operación
SET @FechaOperacion = @xmlData.value('(//FechaOperacion/@Fecha)[1]', 'DATE');

-- Recorrer los elementos <NuevoEmpleado> en el XML
DECLARE @EmpleadoIndex INT;
DECLARE @TotalEmpleados INT;

SELECT @TotalEmpleados = @xmlData.value('count(//NuevoEmpleado)', 'INT');
SET @EmpleadoIndex = 1;

WHILE @EmpleadoIndex <= @TotalEmpleados
BEGIN
    -- Obtener los datos del empleado actual
    SELECT
        @NuevoEmpleadoNombre = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@Nombre)[1]', 'VARCHAR(50)'),
        @IdTipoDocumento = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@IdTipoDocumento)[1]', 'INT'),
        @ValorTipoDocumento = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@ValorTipoDocumento)[1]', 'INT'),
        @IdDepartamento = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@IdDepartamento)[1]', 'INT'),
        @IdPuesto = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@IdPuesto)[1]', 'INT'),
        @Usuario = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@Usuario)[1]', 'VARCHAR(16)'),
        @Password = @xmlData.value('(//NuevoEmpleado[' + CAST(@EmpleadoIndex AS VARCHAR) + ']/@Password)[1]', 'VARCHAR(16)');

    -- Insertar datos del empleado en la tabla Empleado
    INSERT INTO Pruebas.dbo.Empleado (nombre, valorDocid, fechaNacimiento, puestoId, departamentoId, jornadaId, PlanillaSemXEmpId)
    VALUES 
	(@NuevoEmpleadoNombre, 
	@ValorTipoDocumento, 
	@FechaOperacion,
	@IdPuesto, 
	@IdDepartamento, 
	1, 
	1 

    -- Incrementar el índice del empleado
    SET @EmpleadoIndex = @EmpleadoIndex + 1;
END
