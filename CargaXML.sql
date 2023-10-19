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
INSERT INTO dbo.TiposDeDocumentoIdentidad
    ([Id]
    , [Nombre])
SELECT
    T.TipoDocuIdentidad.value('@Id', 'INT') AS Id,
    T.TipoDocuIdentidad.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS T(TipoDocuIdentidad);

-- Insertar tipos de jornada con el xml cargado
INSERT INTO dbo.TiposDeJornada
    ([Id]
    , [Nombre]
    , [HoraInicio]
    , [HoraFin])
SELECT
    T.TipoDeJornada.value('@Id', 'INT') AS Id,
    T.TipoDeJornada.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.TipoDeJornada.value('@HoraInicio', 'TIME') AS HoraInicio,
    T.TipoDeJornada.value('@HoraFin', 'TIME') AS HoraFin
FROM @xmlData.nodes('/Catalogos/TiposDeJornadas/TipoDeJornada') AS T(TipoDeJornada);

-- Insertar puestos con el xml cargado
INSERT INTO dbo.Puestos
    ([Nombre]
    , [SalarioXHora])
SELECT
    T.Puesto.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.Puesto.value('@SalarioXHora', 'MONEY') AS SalarioXHora
FROM @xmlData.nodes('/Catalogos/Puestos/Puesto') AS T(Puesto);

-- Insertar departamentos con el xml cargado
INSERT INTO dbo.Departamentos
    ([Id]
    , [Nombre])
SELECT
    T.Departamento.value('@Id', 'INT') AS Id,
    T.Departamento.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/Departamentos/Departamento') AS T(Departamento);

-- Insertar feriados con el xml cargado
INSERT INTO dbo.Feriados
    ([Id]
    , [Nombre]
    , [Fecha])
SELECT
    T.Feriado.value('@Id', 'INT') AS Id,
    T.Feriado.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.Feriado.value('@Fecha', 'DATE') AS Fecha
FROM @xmlData.nodes('/Catalogos/Feriados/Feriado') AS T(Feriado);

-- Insertar tipos de movimiento con el xml cargado
INSERT INTO dbo.TiposDeMovimiento
    ([Id]
    , [Nombre])
SELECT
    T.TipoDeMovimiento.value('@Id', 'INT') AS Id,
    T.TipoDeMovimiento.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/TiposDeMovimiento/TipoDeMovimiento') AS T(TipoDeMovimiento);

-- Insertar tipos de deducción con el xml cargado
INSERT INTO dbo.TiposDeDeduccion
    ([Id]
    , [Nombre]
    , [Obligatorio]
    , [Porcentual]
    , [Valor])
SELECT
    T.TipoDeDeduccion.value('@Id', 'INT') AS Id,
    T.TipoDeDeduccion.value('@Nombre', 'VARCHAR(128)') AS Nombre,
    T.TipoDeDeduccion.value('@Obligatorio', 'VARCHAR(3)') AS Obligatorio,
    T.TipoDeDeduccion.value('@Porcentual', 'VARCHAR(3)') AS Porcentual,
    T.TipoDeDeduccion.value('@Valor', 'DECIMAL(10, 4)') AS Valor
FROM @xmlData.nodes('/Catalogos/TiposDeDeduccion/TipoDeDeduccion') AS T(TipoDeDeduccion);

-- Insertar usuarios con el xml cargado
INSERT INTO dbo.Usuarios
    ([Nombre]
    , [Clave]
    , [Tipo])
SELECT
    T.Usuario.value('@Username', 'VARCHAR(32)') AS Nombre,
    T.Usuario.value('@Pwd', 'VARCHAR(32)') AS Clave,
    T.Usuario.value('@Tipo', 'INT') AS Tipo
FROM @xmlData.nodes('/Catalogos/UsuariosAdministradores/Usuario') AS T(Usuario);

-- Insertar tipos de evento con el xml cargado
INSERT INTO dbo.TiposDeEvento
    ([Id]
    , [Nombre])
SELECT
    T.TipoEvento.value('@Id', 'INT') AS Id,
    T.TipoEvento.value('@Nombre', 'VARCHAR(128)') AS Nombre
FROM @xmlData.nodes('/Catalogos/TiposdeEvento/TipoEvento') AS T(TipoEvento);
