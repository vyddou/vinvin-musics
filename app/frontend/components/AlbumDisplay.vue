<template>
  <div v-if="loading" class="text-center text-gray-500">
    chargement de l'album...
  </div>

  <div v-else-if="error" class="text-center text-red-500">
    Erreur : {{ error }}
  </div>

  <div v-else-if="!album" class="text-center text-gray-600">
    Aucun album trouvé
  </div>

  <div v-else class="bg-white shadow-lg rounded-lg p-6">
    <h2 class="text-2xl font-semibold mb-2">{{ album.title }}</h2>
    <p class="text-gray-700 mb-4">{{ album.description }}</p>
    <img
      v-if="album.cover_url"
      :src="album.cover_url"
      alt="Pochette"
      class="w-full h-auto mb-6 rounded"
    />

<h3 class="text-xl font-medium mb-2">Pistes</h3>

     <ul class="list-decimal list-inside mb-6">
      <li v-for="track in album.tracks" :key="track.id"
      class="py-1 border-b last:border-b-0 border-gray-200">

        {{ track.track_number }}. {{ track.title }}
      </li>
    </ul>


    <audio
      v-if="album.tracks.length"
      controls
      class="w-full"
    >
      <source
        :src="album.tracks[0].audio_file_url"
        type="audio/mpeg"
      />
      Votre navigateur ne supporte pas l’audio.
    </audio>

  </div>
</template>

<script setup>
import { ref, onMounted} from 'vue';

const album = ref(null); // variable pour l'album qu'on init a 0
const loading = ref(true); // permet l'affichage d'un message de chargement pour le user
const error = ref(null); // variable d'erreur init a 0

onMounted(async () => {
  try {
    const response = await fetch('/api/v1/albums');
    if (!response.ok) {
      throw new Error("La réponse du réseau n'était pas ok");
    }

    const data = await response.json();
    console.log('Données reçues par le frontend :', data);

    if (data.length > 0) {
      album.value = data[0]; // Prend le premier album si il y en a
    }
    // Sinon album.value reste null et le template affiche "Aucun album trouvé"

  } catch (e) {
    error.value = "Impossible de charger l'album";
    console.error(e);
  } finally {
    loading.value = false;
  }
});
</script>
