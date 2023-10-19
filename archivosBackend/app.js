// Importación de módulos
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const morgan = require('morgan');
const cors = require('cors');
const conn = require('./Connection.js'); // Importar el módulo de conexión
const controller = require('./Controller.js')

// Crear instancia de la aplicación Express
const app = express();
const port = 8080; // Puerto en el que se escucharán las solicitudes


// Configuraciones de middleware
app.use(cors()); // Habilitar CORS para permitir solicitudes de diferentes dominios
app.use(morgan('dev')); // Registro de solicitudes en la consola en formato 'dev'
app.use(bodyParser.urlencoded({ extended: false })); // Analizar datos URL-encoded en las solicitudes
app.use(express.json()); // Analizar datos JSON en las solicitudes

// Enrutador
const router = express.Router(); // Crear un enrutador Express


// Configurar las rutas utilizando las funciones correspondientes
router.get('/select', controller.select); // Ruta para obtener artículos
router.post('/insert', controller.insert); // Ruta para insertar artículos


app.use('/', router); // Asociar el enrutador a la ruta raíz



// Iniciar el servidor
app.listen(port, () => {
console.log("Servidor en línea en el puerto:", port);
});


