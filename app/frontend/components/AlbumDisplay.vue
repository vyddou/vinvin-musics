<script setup>
// on importe les APIs de Vue
import { ref, onMounted, onBeforeUnmount } from 'vue'       // ← refs + hooks

// ---- ÉTAT ----
const album = ref(null)                                     // ← album + pistes
const isLoading = ref(true)                                 // ← état de chargement
const errorMsg = ref(null)                                  // ← message d’erreur

const audioEl = ref(null)                                   // ← lecteur audio unique (caché)
const currentTrackId = ref(null)                            // ← id de la piste active
const isPlaying = ref(false)                                // ← en cours de lecture ?

// ---- CHARGEMENT DES DONNÉES ----
onMounted(async () => {                                     // ← au montage du composant
  try {
    const listRes = await fetch('/api/v1/albums')           // ← récupère tous les albums
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status}`)
    const albums = await listRes.json()                     // ← parse JSON

    const target = albums.find(a => a.title === 'Simone')   // ← cherche l’album "Simone"
                  || albums[0]                              // ← fallback: 1er album
    if (!target) throw new Error('Aucun album')

    const showRes = await fetch(`/api/v1/albums/${target.id}`) // ← charge le détail + pistes
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status}`)
    album.value = await showRes.json()                      // ← stocke l’album
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}` // ← affiche l’erreur
  } finally {
    isLoading.value = false                                 // ← fin du chargement
  }

  // branche les événements du lecteur audio
  if (audioEl.value) {                                      // ← sécurité
    audioEl.value.addEventListener('ended', onEnded)        // ← quand la piste finit
    audioEl.value.addEventListener('pause', () => isPlaying.value = false) // ← pause
    audioEl.value.addEventListener('play',  () => isPlaying.value = true)  // ← play
  }
})

// nettoyage des listeners au démontage
onBeforeUnmount(() => {                                     // ← avant destruction
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded)
})

// ---- PLAYER ----
const playTrack = async (track) => {                        // ← lance une piste
  if (currentTrackId.value !== track.id) {                  // ← si ce n’est pas la même
    currentTrackId.value = track.id                         // ← mémorise la piste
    audioEl.value.src = track.audio_url                     // ← change la source audio
  }
  try {
    await audioEl.value.play()                              // ← joue
    isPlaying.value = true                                  // ← maj état
  } catch (e) {
    console.warn('Lecture bloquée :', e)                    // ← cas autoplay bloqué
    isPlaying.value = false
  }
}

const pause = () => {                                       // ← met en pause
  audioEl.value?.pause()
  isPlaying.value = false
}

const toggle = (t) => {                                     // ← bascule play/pause
  (currentTrackId.value === t.id && isPlaying.value) ? pause() : playTrack(t)
}

const onEnded = () => {                                     // ← quand la piste finit
  const tracks = album.value?.tracks || []                  // ← liste des pistes
  const i = tracks.findIndex(t => t.id === currentTrackId.value) // ← index courant
  const next = tracks[i + 1]                                // ← piste suivante
  next ? playTrack(next) : (isPlaying.value = false, currentTrackId.value = null) // ← fin d’album
}

const isActive = (t) => currentTrackId.value === t.id       // ← piste sélectionnée ?
const isActiveAndPlaying = (t) => isActive(t) && isPlaying.value // ← en lecture ?
</script>

<template>
  <!-- conteneur global -->
  <div class="min-h-screen bg-gray-50 flex flex-col items-center py-12 px-4">
    <!-- carte principale -->
    <div class="w-full max-w-4xl rounded-2xl shadow-lg bg-white p-6">
      <!-- header -->
      <div class="grid grid-cols-1 md:grid-cols-[1.2fr_1fr] gap-6 items-center mb-6">
        <!-- image d’album (cover) -->
        <img
          :src="album?.cover_url"
          alt="Cover album"
          class="w-full aspect-square rounded-2xl object-cover bg-gray-100"
        />
        <!-- détails -->
        <div class="flex flex-col justify-center">
          <h1 class="text-3xl font-extrabold tracking-tight mb-2">Muso</h1>       <!-- artiste -->
          <p class="text-gray-700">
            <span class="font-semibold">Album :</span>
            <span class="italic">{{ album?.title || '' }}</span>                  <!-- titre album -->
          </p>
          <p v-if="album?.release_year" class="text-gray-500">Sortie : {{ album.release_year }}</p>
        </div>
      </div>

      <!-- états -->
      <div v-if="isLoading" class="text-gray-500">Chargement…</div>              <!-- loading -->
      <div v-else-if="errorMsg" class="text-red-600">{{ errorMsg }}</div>        <!-- erreur -->

      <!-- liste des pistes -->
      <ul v-else class="divide-y divide-gray-100">
       <li
          v-for="t in album.tracks"
          :key="t.id"
          class="flex items-center gap-4 py-3 px-2 rounded-lg hover:bg-gray-50"
          :class="isActive(t) ? 'bg-emerald-100' : ''"
        >
          <!-- numéro -->
          <div class="w-8 text-right text-gray-400">{{ t.track_number }}</div>   <!-- n° de piste -->

          <!-- titre + artiste -->
          <div class="flex-1">
            <p class="font-medium text-gray-900 leading-tight">{{ t.title }}</p>  <!-- titre -->
            <p class="text-xs text-gray-500">Muso</p>                              <!-- artiste -->
          </div>

          <!-- bouton play/pause stylé -->
          <button
            @click="toggle(t)"
            class="inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold
                  border transition hover:shadow active:scale-95"
            :class="isActiveAndPlaying(t)
              ? 'bg-emerald-600 text-white border-emerald-600'
              : 'bg-white text-gray-700 border-gray-300'"
          >
            <span v-if="isActiveAndPlaying(t)">Pause</span>
            <span v-else>Play</span>
          </button>
        </li>
      </ul>
    </div>

    <!-- lecteur audio global (caché) -->
    <audio ref="audioEl" class="hidden"></audio>
  </div>
</template>

<style scoped>
/* rien de particulier, tout est géré par Tailwind */
</style>
