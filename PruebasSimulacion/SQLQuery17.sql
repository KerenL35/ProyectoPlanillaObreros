IF @FechaActual = @PrimerJueves
BEGIN

	salarioNeto = salarioBruto - totalDeducciones;

    IF @FechaActual = @UltimoJueves
    BEGIN

        DECLARE @FechaTemporal DATE = DATEADD(MONTH, 1, @FechaActual);

        EXEC ObtenerJuevesDelMes @FechaInput, @PrimerJueves OUTPUT, @UltimoJueves OUTPUT;

        -- Crear nueva planilla para el próximo mes
		INSERT INTO PlanillaMesXEmp
			(salarioBruto, totalDeducciones, mesPlanillaId, valorTipoDocumentoId)
		SELECT 0.0, 0.0, (SELECT MAX(id)
			FROM MesPlanilla), valorTipoDocumento
		FROM Empleado

    END

		INSERT INTO PlanillaSemXEmp
			(salarioNeto, semanaPlanillaId, planillaMesXempId,
			salarioBruto, totalDeducciones)
		SELECT 0.0, (SELECT MAX(id)
			FROM SemanaPlanilla),
			(SELECT MAX(id)
			FROM PlanillaMesXEmp
			WHERE valorTipoDocumentoId = emp.valorTipoDocumento),
			0.0, 0.0
		FROM Empleado emp
	
END