import { createApp } from 'vue';
import HelloWorld from '../components/HelloWorld.vue';

// Attend que le DOM soit chargé avant de lancer l'app Vue
document.addEventListener('DOMContentLoaded', () => {
  // Ces deux lignes doivent être à l'intérieur pour s'exécuter au bon moment
  const app = createApp(HelloWorld);
  app.mount('#app');
});
