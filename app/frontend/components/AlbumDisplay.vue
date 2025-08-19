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
    <!-- titre et description / image identiques -->
    <h2 class="text-2xl font-semibold mb-2">{{ album.title }}</h2>
    <p class="text-gray-700 mb-4">{{ album.description }}</p>
    <img
      v-if="album.cover_url"
      :src="album.cover_url"
      alt="Pochette"
      class="w-full h-auto mb-6 rounded"
    />

    <!-- 1 seul titre Pistes, hors de tout <ul> -->
    <h3 class="text-xl font-medium mb-4">Pistes</h3>

    <!-- 2 façons de lister :
         a) directement en div + composants
         b) ou en <ul><li> via TrackItem -->
    <div class="space-y-1 mb-6">
      <TrackItem
        v-for="track in album.tracks"
        :key="track.id"
        :track="track"
      />
    </div>

    <!-- player global géré par AudioPlayerBar.vue -->
    <AudioPlayerBar />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import TrackItem from './TrackItem.vue'
import AudioPlayerBar from './AudioPlayerBar.vue'

const album = ref(null)
const loading = ref(true)
const error = ref(null)

onMounted(async () => {
  try {
    const response = await fetch('/api/v1/albums')
    if (!response.ok) throw new Error("La réponse du réseau n'était pas ok")
    const data = await response.json()
    album.value = data[0] || null
  } catch (e) {
    error.value = "Impossible de charger l'album"
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>
