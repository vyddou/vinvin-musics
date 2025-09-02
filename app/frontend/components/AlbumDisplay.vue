<script setup>
// =====================
// Imports Vue + icônes
// =====================
import { ref, onMounted, onBeforeUnmount, computed, nextTick } from 'vue' // ← nextTick permet d'attendre le rendu DOM
import { Play, Pause, SkipBack, SkipForward } from 'lucide-vue-next'      // ← icônes (assure-toi d'avoir: yarn add lucide-vue-next)

// =====================
// ÉTAT GLOBAL DU PLAYER
// =====================
// album chargé depuis l'API (avec ses pistes)
const album = ref(null)                // ← objet album
// états d'UI
const isLoading = ref(true)            // ← indique si on charge
const errorMsg = ref(null)             // ← message d'erreur lisible si API KO
// player
const audioEl = ref(null)              // ← référence à l'élément <audio> unique (caché)
const currentTrackId = ref(null)       // ← id de la piste active
const isPlaying = ref(false)           // ← true si lecture en cours
const currentTime = ref(0)             // ← temps courant (s)
const duration = ref(0)                // ← durée totale (s)

// =====================
// Helpers d'affichage
// =====================
// Formate un nombre de secondes "90" -> "1:30"
const formatTime = (sec) => {          // ← utilitaire simple
  if (!sec || sec === Infinity) return '0:00'
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

// Ratio 0..1 pour la barre de progression
const progress = computed(() => {      // ← calcul réactif
  if (!duration.value) return 0
  return Math.min(1, Math.max(0, currentTime.value / duration.value))
})

// Piste active (objet complet) pour affichage sticky
const activeTrack = computed(() => {   // ← renvoie la piste active ou null
  if (!album.value || !currentTrackId.value) return null
  return album.value.tracks.find(t => t.id === currentTrackId.value) || null
})

// =====================
// Fonctions demandées
// =====================
// True si la piste est la piste active
const isActive = (track) => {          // ← utile pour surligner la ligne
  return currentTrackId.value === track.id
}

// True si la piste est active ET en cours de lecture
const isActiveAndPlaying = (track) => {// ← utile pour l'état du bouton
  return currentTrackId.value === track.id && isPlaying.value
}

// =====================
// Configuration <audio>
// =====================
// Branche tous les listeners une fois que l'élément <audio> est dans le DOM
const setupAudioEvents = () => {
  if (!audioEl.value) return                        // ← sécurité si ref absente

  // Gestion d'erreur audio (ex: source introuvable)
  audioEl.value.addEventListener('error', (e) => {  // ← écouteur d'erreur
    console.error('Erreur audio:', e)
    errorMsg.value = 'Erreur de lecture audio'
    isPlaying.value = false
  })

  // Quand la piste se termine
  audioEl.value.addEventListener('ended', onEnded)

  // Mise à jour de l'état lecture/pause
  audioEl.value.addEventListener('pause', () => { isPlaying.value = false })
  audioEl.value.addEventListener('play',  () => { isPlaying.value = true  })

  // Mise à jour du temps courant + durée pendant la lecture
  audioEl.value.addEventListener('timeupdate', () => {
    currentTime.value = audioEl.value.currentTime || 0
    duration.value = audioEl.value.duration || 0
  })

  // Durée disponible dès que les métadonnées sont chargées
  audioEl.value.addEventListener('loadedmetadata', () => {
    duration.value = audioEl.value.duration || 0
  })
}

// =====================
// Cycle de vie (montage)
// =====================
onMounted(async () => {
  try {
    // 1) on récupère la liste des albums (index)
    const listRes = await fetch('/api/v1/albums')              // ← GET index
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status} (index)`)
    const albums = await listRes.json()                        // ← parse JSON

    // 2) on choisit "Simone" si présent, sinon le premier
    const target = albums.find(a => a.title === 'Simone') || albums[0]
    if (!target) throw new Error('Aucun album')

    // 3) on récupère le détail (show) pour les pistes
    const showRes = await fetch(`/api/v1/albums/${target.id}`) // ← GET show
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status} (show)`)
    album.value = await showRes.json()                         // ← stocke l'album
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}`    // ← message lisible
  } finally {
    isLoading.value = false                                    // ← fin du chargement
    await nextTick()                                           // ← attend que le DOM soit peint (audio ref dispo)
    setupAudioEvents()                                         // ← branche les events <audio> proprement
  }

  // Raccourcis clavier globaux (Espace / ← / →)
  window.addEventListener('keydown', onKeyDown)                // ← binding global
})

// Nettoyage au démontage
onBeforeUnmount(() => {
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded) // ← retire un listener explicite
  window.removeEventListener('keydown', onKeyDown)                        // ← retire raccourcis globaux
})

// =====================
// Actions du player
// =====================
// Lance la lecture d'une piste donnée
const playTrack = async (track) => {
  if (!audioEl.value) return
  // Si on change de piste → on remplace la source
  if (currentTrackId.value !== track.id) {
    currentTrackId.value = track.id
    audioEl.value.src = track.audio_url
    currentTime.value = 0
  }
  // On tente de jouer (peut être bloqué par le navigateur si pas d'interaction)
  try {
    await audioEl.value.play()
    isPlaying.value = true
  } catch (e) {
    console.warn('Lecture bloquée :', e)
    isPlaying.value = false
  }
}

// Met en pause la lecture
const pause = () => {
  if (!audioEl.value) return
  audioEl.value.pause()
  isPlaying.value = false
}

// Bascule Play/Pause pour une piste
const toggle = (t) => {
  (currentTrackId.value === t.id && isPlaying.value) ? pause() : playTrack(t)
}

// Piste suivante / précédente
const playNext = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)
  const next = list[idx + 1]
  if (next) playTrack(next)
}
const playPrev = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)
  const prev = list[idx - 1]
  if (prev) playTrack(prev)
}

// Quand la piste se termine: enchaîner la suivante sinon stop
const onEnded = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)
  const next = list[idx + 1]
  next ? playTrack(next) : (isPlaying.value = false, currentTrackId.value = null)
}

// =====================
// Seek: clic progress bar
// =====================
// Se déplacer dans la piste en cliquant sur la barre de progression
const onProgressClick = (e) => {
  if (!audioEl.value || !duration.value) return
  const rect = e.currentTarget.getBoundingClientRect()
  const x = e.clientX - rect.left
  const ratio = Math.min(1, Math.max(0, x / rect.width))
  const newTime = ratio * duration.value
  audioEl.value.currentTime = newTime
  currentTime.value = newTime
}

// =====================
// Raccourcis clavier
// =====================
// Espace = Play/Pause ; → = suivante ; ← = précédente
const onKeyDown = (e) => {
  if (['Space', 'ArrowRight', 'ArrowLeft'].includes(e.code)) e.preventDefault()
  if (e.code === 'Space') {
    if (activeTrack.value) {
      isPlaying.value ? pause() : playTrack(activeTrack.value)
    } else if (album.value?.tracks?.length) {
      playTrack(album.value.tracks[0])
    }
  } else if (e.code === 'ArrowRight') {
    playNext()
  } else if (e.code === 'ArrowLeft') {
    playPrev()
  }
}
</script>

<template>
  <!-- Conteneur principal avec padding-bas pour dégager la sticky bar -->
  <div class="min-h-screen bg-gray-50 flex flex-col items-center py-12 px-4 pb-28">
    <!-- Carte principale -->
    <div class="w-full max-w-4xl rounded-2xl shadow-lg bg-white p-6">
      <!-- États -->
      <div v-if="isLoading" class="text-gray-500">Chargement…</div>
      <div v-else-if="errorMsg" class="text-red-600">{{ errorMsg }}</div>
      <div v-else-if="!album" class="text-gray-600">Aucun album trouvé.</div>

      <!-- Contenu album -->
      <div v-else>
        <!-- Header: cover + infos -->
        <div class="grid grid-cols-1 md:grid-cols-[1.2fr_1fr] gap-6 items-center mb-6">
          <img :src="album.cover_url" alt="Cover album" class="w-full aspect-square rounded-2xl object-cover bg-gray-100" />
          <div class="flex flex-col justify-center">
            <h1 class="text-3xl font-extrabold tracking-tight mb-2">Muso</h1>
            <p class="text-gray-700"><span class="font-semibold">Album :</span> <span class="italic">{{ album.title }}</span></p>
            <p v-if="album.release_year" class="text-gray-500">Sortie : {{ album.release_year }}</p>
          </div>
        </div>

        <!-- Liste des pistes -->
        <ul v-if="album.tracks && album.tracks.length" class="divide-y divide-gray-100">
          <li
            v-for="t in album.tracks"
            :key="t.id"
            class="flex items-center gap-4 py-3 px-2 rounded-lg hover:bg-gray-50"
            :class="isActive(t) ? 'bg-emerald-100' : ''"
          >
            <div class="w-8 text-right text-gray-400">{{ t.track_number }}</div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-gray-900 leading-tight truncate">{{ t.title }}</p>
              <p class="text-xs text-gray-500 truncate">Muso</p>
            </div>
            <button
              @click="toggle(t)"
              class="inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold
                     border transition hover:shadow active:scale-95"
              :class="isActiveAndPlaying(t)
                ? 'bg-emerald-600 text-white border-emerald-600'
                : 'bg-white text-gray-700 border-gray-300'"
              aria-label="Play/Pause"
            >
              <Pause v-if="isActiveAndPlaying(t)" :size="18" />
              <Play v-else :size="18" />
              <span class="sr-only">Play/Pause</span>
            </button>
          </li>
        </ul>

        <div v-else class="text-gray-500">Aucune piste dans cet album.</div>
      </div>
    </div>

    <!-- Lecteur audio global caché -->
    <audio ref="audioEl" class="hidden"></audio>

    <!-- Sticky Player en bas -->
    <div
      v-if="activeTrack"
      class="fixed inset-x-0 bottom-0 z-50 border-t bg-white shadow-md"
      style="padding-bottom: env(safe-area-inset-bottom);"
    >
      <div class="max-w-4xl mx-auto px-4 py-3">
        <div class="flex items-center gap-3">
          <div class="min-w-0">
            <p class="font-medium text-gray-900 truncate">{{ activeTrack.title }}</p>
            <p class="text-xs text-gray-500 truncate">Muso — {{ album.title }}</p>
          </div>

          <div class="flex items-center gap-2 ml-auto">
            <button
              @click="playPrev"
              class="rounded-full border w-9 h-9 flex items-center justify-center hover:shadow active:scale-95"
              aria-label="Précédent"
            >
              <SkipBack :size="16" />
            </button>

            <button
              @click="isPlaying ? pause() : (activeTrack ? playTrack(activeTrack) : null)"
              class="rounded-full border w-10 h-10 flex items-center justify-center font-semibold hover:shadow active:scale-95"
              :class="isPlaying ? 'bg-emerald-600 text-white border-emerald-600' : 'bg-white text-gray-700 border-gray-300'"
              aria-label="Play/Pause"
            >
              <Pause v-if="isPlaying" :size="18" />
              <Play v-else :size="18" />
            </button>

            <button
              @click="playNext"
              class="rounded-full border w-9 h-9 flex items-center justify-center hover:shadow active:scale-95"
              aria-label="Suivant"
            >
              <SkipForward :size="16" />
            </button>
          </div>
        </div>

        <div class="mt-2">
          <div class="flex items-center gap-3">
            <span class="text-xs tabular-nums text-gray-600">{{ formatTime(currentTime) }}</span>
            <div class="flex-1 h-2 bg-gray-200 rounded-full cursor-pointer" @click="onProgressClick">
              <div class="h-2 bg-emerald-600 rounded-full" :style="{ width: `${progress * 100}%` }"></div>
            </div>
            <span class="text-xs tabular-nums text-gray-600">{{ formatTime(duration) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
