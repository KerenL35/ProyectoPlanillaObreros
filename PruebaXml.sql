USE Pruebas
DECLARE @xmlData XML	

-- Cargar archivos xml
SET @xmlData = (
	SELECT *
	FROM OPENROWSET(
		BULK 'C:\Users\keren\OneDrive\Escritorio\Bases de Datos I\ProyectoPlanillaObrera\Catalogos2.xml',
		SINGLE_BLOB
	) AS xmlData
);

-- Insertar tipos de documento de identidad con el xml cargado
INSERT INTO dbo.TipoDocIdentidad
		([nombre])
SELECT
    T.TipoDocIdentidad.value('@Nombre', 'VARCHAR(64)') AS Nombre
FROM @xmlData.nodes('/Catalogos/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS T(TipoDocIdentidad);

-- Insertar tipos de jornada con el XML cargado
	INSERT INTO [dbo].[TipoJornada]
		( [nombre], [horaInicio], [horaFin])
	SELECT
		T.Jornada.value('@Id', 'INT'),
		T.Jornada.value('@Nombre', 'VARCHAR(64)') AS Nombre,
		T.Jornada.value('@HoraInicio', 'TIME') AS HoraInicio,
		T.Jornada.value('@HoraFin', 'TIME') AS HoraFin
	FROM @xmlData.nodes('/Catalogos/TiposDeJornadas/TipoDeJornada') AS T(Jornada)

-- Insertar puestos con el xml cargado
INSERT INTO dbo.Puesto
    ([Nombre]
    , [SalarioXHora])
SELECT
    T.Puesto.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.Puesto.value('@SalarioXHora', 'MONEY') AS SalarioXHora
FROM @xmlData.nodes('/Catalogos/Puestos/Puesto') AS T(Puesto);

-- Insertar departamentos con el xml cargado
INSERT INTO dbo.Departamento
		([Nombre])
SELECT
    T.Departamento.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/Departamentos/Departamento') AS T(Departamento);

-- Insertar feriados con el xml cargado
INSERT INTO dbo.Feriado
    ([Nombre]
    , [Fecha])
SELECT
    T.Feriado.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.Feriado.value('@Fecha', 'DATE') AS Fecha
FROM @xmlData.nodes('/Catalogos/Feriados/Feriado') AS T(Feriado);

-- Insertar tipos de deducción con el xml cargado
INSERT INTO dbo.TipoDeduccion
    ([Nombre]
    , [esObligatoria]
    , [esPorcentual]
    , [Valor])
SELECT
    T.TipoDeDeduccion.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.TipoDeDeduccion.value('@Obligatorio', 'VARCHAR(3)') AS esObligatoria,
    T.TipoDeDeduccion.value('@Porcentual', 'VARCHAR(3)') AS esPorcentual,
    T.TipoDeDeduccion.value('@Valor', 'DECIMAL(10, 4)') AS Valor
FROM @xmlData.nodes('/Catalogos/TiposDeDeduccion/TipoDeDeduccion') AS T(TipoDeDeduccion);

-- Insertar datos desde el XML a la tabla TipoMovimientoPlanilla
INSERT INTO dbo.TipoMovimientoPlanilla
    ([nombre])
SELECT
	
    T.TipoDeMovimiento.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/TiposDeMovimiento/TipoDeMovimiento') AS T(TipoDeMovimiento);



-- Insertar usuarios con el xml cargado
INSERT INTO dbo.Usuario
    ([Nombre]
    , [Clave]
    , [Tipo])
SELECT
    T.Usuario.value('@Username', 'VARCHAR(32)') AS Nombre,
    T.Usuario.value('@Pwd', 'VARCHAR(32)') AS Clave,
    T.Usuario.value('@tipo', 'INT') AS Tipo
FROM @xmlData.nodes('/Catalogos/UsuariosAdministradores/Usuario') AS T(Usuario);

-- Insertar tipos de evento con el xml cargado
INSERT INTO dbo.TipoEvento
    ([Nombre])
SELECT
    T.TipoEvento.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/TiposdeEvento/TipoEvento') AS T(TipoEvento);
