import { createApp } from 'vue';
// Importation du composant AlbumDisplay
import AlbumDisplay from '../components/AlbumDisplay.vue';

// Attend que le DOM soit chargé avant de lancer l'app Vue
document.addEventListener('DOMContentLoaded', () => {
  // Composant pour créer l'application Vue
const app = createApp(AlbumDisplay);
  app.mount('#app');
});
