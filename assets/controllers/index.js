// assets/controllers/index.js
import { application } from '../bootstrap.js';


// Importer et enregistrer les contrôleurs ici
import HelloController from './hello_controller.js';
application.register('hello', HelloController);
