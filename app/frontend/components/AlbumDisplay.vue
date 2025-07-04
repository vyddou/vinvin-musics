<script setup>

import { ref, onMounted} from 'vue';

const album = ref(null); // variable pour l'album qu'on init a 0
const loading = ref(true); // permet l'affichage d'un message de chargement pour le user
const error = ref(null); // variable d'erreur init a 0

onMounted(async () => {
  // éxécute le code de manière asynchrone que le composant est visible
  try {
    const response = await fetch('/api/v1/albums'); // appelle l'api et attends jusqu'a sa récupération
    const data = await response.json

    album.value = data[0]; // insére le premier album dans un array

  } catch (e) {
    // en cas d'erreur on la stock dans une variable
    error.value = "Impossible de charger l'album";
    console.error(e);
  } finally {
    // fin de chargement quelque soit le résultat
    loading.value = false;
 }
});
</script>
