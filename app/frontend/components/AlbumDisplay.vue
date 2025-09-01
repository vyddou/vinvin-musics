<script setup>
import { ref, onMounted } from 'vue'

const album = ref(null)

onMounted(async () => {
  // on récupère l’album "Simone" (id=1)
  const res = await fetch('/api/v1/albums/1')
  album.value = await res.json()
})
</script>

<template>
  <div v-if="album">
    <!-- Infos album -->
    <div class="flex flex-col items-center mb-8">
      <img :src="album.cover_url" alt="cover" class="w-32 h-32 rounded shadow-lg mb-4" />
      <h2 class="text-2xl font-bold">Muso</h2>
      <p class="text-lg text-gray-600 italic">Album : {{ album.title }}</p>
    </div>

    <!-- Liste des pistes -->
    <ul>
      <li
        v-for="track in album.tracks"
        :key="track.id"
        class="flex items-center space-x-4 mb-2"
      >
        <span>{{ track.track_number }}. {{ track.title }}</span>
        <audio :src="track.audio_url" controls class="ml-auto"></audio>
      </li>
    </ul>
  </div>

  <p v-else>Chargement...</p>
</template>
