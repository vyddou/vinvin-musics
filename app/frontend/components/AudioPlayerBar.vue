<template>
  <div
    v-if="currentTrack"
    class="fixed bottom-0 left-0 right-0 bg-white shadow-md p-4 flex items-center"
  >
    <button @click="togglePlay" class="mr-4">
      {{ isPlaying ? '⏸️' : '▶️' }}
    </button>
    <div class="flex-1">
      <div class="font-medium">{{ currentTrack.title }}</div>
      <!-- Si tu as un artist -->
      <div v-if="currentTrack.artist" class="text-sm text-gray-600">
        {{ currentTrack.artist }}
      </div>
    </div>
    <audio
      ref="audio"
      class="hidden"
      :src="currentTrack.audio_file_url"
      @ended="onEnded"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'            // ← Bien importer computed, watch, onMounted
import { playerStore } from '../store/player'                   // ← Ton store

// Référence au tag <audio>
const audio = ref(null)

// Computed pour la piste courante et l'état
const currentTrack = computed(() => playerStore.queue[playerStore.currentIndex] || null)
const isPlaying    = computed(() => playerStore.isPlaying)

// Bouton play/pause
function togglePlay() {
  if (!currentTrack.value) return
  playerStore.isPlaying = !playerStore.isPlaying
}

// Quand la piste se termine, on passe à la suivante
function onEnded() {
  playerStore.onTrackEnded()
}

// Surveille le changement de lecture pour piloter l'élément <audio>
watch(isPlaying, (playing) => {
  if (!audio.value) return
  playing ? audio.value.play() : audio.value.pause()
})

// Quand la piste change, on recharge la source et on joue si besoin
onMounted(() => {
  watch(currentTrack, (track) => {
    if (!audio.value || !track) return
    audio.value.load()
    if (playerStore.isPlaying) audio.value.play()
  }, { immediate: true })
})
</script>
