// Importar el módulo de conexión desde la carpeta ../Prueba de Concepto
const conn = require('./Connection.js')

/*
Funcion para llamar sp que muestra los articulos
*/
const select = async (req, res) => {
    try {
        // Obtener una conexión desde el módulo de conexión
        const pool = await conn.getConnection();

        // Ejecutar un procedimiento almacenado llamado MostrarArticulosOrdenados
        const result = await pool.request()
            .output('outResultCode', 0)
            .execute('MostrarArticulosOrdenados');

        // Enviar la lista de artículos como respuesta en formato JSON
        res.status(200).json(result.recordset);
    } catch (error) {
        // Manejo de errores en caso de problemas durante la conexión o ejecución
        console.error('Error:', error.message);
        res.status(500).send('Error en el servidor');
    }
};


/*
Función para realizar una consulta para validar usuario
*/
const ValidarUsuario = async (req, res) => {
    try {
        // Conexión a la base de datos usando el pool de conexiones
        const pool = await conn.getConnection();
        let outResultCode = 0;

        const result = await pool.request()
            .input('inNombre', req.body.inNombre) 
            .input('inClave', req.body.inClave)
            .output('outResultLogin', 0)
            .output('outResultCode', 0)
            .execute('ValidarUsuario');
        if (result.output.outResultLogin === "0") {
            console.log (result.output)
            res.status(200).json({
                success: true,
                message: "Consulta exitosa"

            });
        } 
        else {
            console.log (result.output)
            res.status(404).json({
                success: false,
                message: "Usuario o contraseña invalidos"
            });
        }
    } catch (error) {
        // Manejo de errores y envío de respuesta en caso de error
        res.status(500).json({
            success: false,
            message: "Ha ocurrido un error durante la consulta"
        });
    }
};




exports.insert = insert;

exports.ValidarUsuario = ValidarUsuario;

