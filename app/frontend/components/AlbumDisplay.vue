<script setup>

import { ref, onMounted} from 'vue';

const album = ref(null); // variable pour l'album qu'on init a 0
const loading = ref(true); // permet l'affichage d'un message de chargement pour le user
const error = ref(null); // variable d'erreur init a 0

onMounted(async () => {
  // éxécute le code de manière asynchrone que le composant est visible
  try {
    const response = await fetch('/api/v1/albums'); // appelle l'api et attends jusqu'a sa récupération
    if (!response.ok) { // on vérifie que  la réponse du server soit dans les 200 et non 400 ou 500
      throw new Error ("La réponse du réseau n'était pas ok"); //Si la réponse n'est pas bonne, on arrête immédiatement le bloc try et on "jette" une erreur. Le programme va sauter directement au bloc catch
    }

    const data = await response.json(); // si bonne réponse on la tranforme en obj js
    album.value = data[0]; // insére le premier album dans un array

  } catch (e) {
    // en cas d'erreur on la stock dans une variable
    error.value = "Impossible de charger l'album";
    console.error(e); // on affiche l'erreur technique complete dans la console
  } finally {
    // fin de chargement quelque soit le résultat
    loading.value = false;
 }
});
</script>
