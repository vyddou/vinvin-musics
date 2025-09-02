<script setup>
// ===== Imports Vue =====
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'

// ===== ÉTAT GÉNÉRAL =====
// album récupéré via l'API (détail + pistes)
const album = ref(null)
// états UI
const isLoading = ref(true)
const errorMsg = ref(null)

// ===== PLAYER GLOBAL (un seul <audio>) =====
const audioEl = ref(null)        // référence vers l'élément <audio>
const currentTrackId = ref(null) // id de la piste active
const isPlaying = ref(false)     // true si le player joue
const currentTime = ref(0)       // temps courant (secondes)
const duration = ref(0)          // durée totale (secondes)

// formatte 90 -> "1:30"
const formatTime = (sec) => {
  if (!sec || sec === Infinity) return '0:00'
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

// ratio 0..1 pour la barre de progression
const progress = computed(() => {
  if (!duration.value) return 0
  return Math.min(1, Math.max(0, currentTime.value / duration.value))
})

// piste active (objet)
const activeTrack = computed(() => {
  if (!album.value || !currentTrackId.value) return null
  return album.value.tracks.find(t => t.id === currentTrackId.value) || null
})

// ===== CHARGEMENT DE L'ALBUM =====
onMounted(async () => {
  try {
    // 1) liste des albums
    const listRes = await fetch('/api/v1/albums')
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status} (index)`)
    const albums = await listRes.json()

    // 2) choisir "Simone" si présent, sinon le premier
    const target = albums.find(a => a.title === 'Simone') || albums[0]
    if (!target) throw new Error('Aucun album')

    // 3) détail de l'album
    const showRes = await fetch(`/api/v1/albums/${target.id}`)
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status} (show)`)
    album.value = await showRes.json()
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}`
  } finally {
    isLoading.value = false
  }

  // écouteurs du lecteur audio global
  if (audioEl.value) {
    audioEl.value.addEventListener('ended', onEnded)
    audioEl.value.addEventListener('pause', () => { isPlaying.value = false })
    audioEl.value.addEventListener('play',  () => { isPlaying.value = true })
    audioEl.value.addEventListener('timeupdate', () => {
      currentTime.value = audioEl.value.currentTime || 0
      duration.value = audioEl.value.duration || 0
    })
    audioEl.value.addEventListener('loadedmetadata', () => {
      duration.value = audioEl.value.duration || 0
    })
  }

  // raccourcis clavier globaux
  window.addEventListener('keydown', onKeyDown)
})

onBeforeUnmount(() => {
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded)
  window.removeEventListener('keydown', onKeyDown)
})

// ===== ACTIONS PLAYER =====
const playTrack = async (track) => {
  if (!audioEl.value) return
  if (currentTrackId.value !== track.id) {
    currentTrackId.value = track.id
    audioEl.value.src = track.audio_url
    currentTime.value = 0
  }
  try {
    await audioEl.value.play()
    isPlaying.value = true
  } catch (e) {
    console.warn('Lecture bloquée :', e)
    isPlaying.value = false
  }
}

const pause = () => {
  if (!audioEl.value) return
  audioEl.value.pause()
  isPlaying.value = false
}

const toggle = (t) => {
  (currentTrackId.value === t.id && isPlaying.value) ? pause() : playTrack(t)
}

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

const onEnded = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)
  const next = list[idx + 1]
  next ? playTrack(next) : (isPlaying.value = false, currentTrackId.value = null)
}

// états pour styler les lignes
const isActive = (t) => currentTrackId.value === t.id
const isActiveAndPlaying = (t) => isActive(t) && isPlaying.value

// ===== BARRE DE PROGRESSION =====
const onProgressClick = (e) => {
  if (!audioEl.value || !duration.value) return
  const rect = e.currentTarget.getBoundingClientRect()
  const x = e.clientX - rect.left
  const ratio = Math.min(1, Math.max(0, x / rect.width))
  const newTime = ratio * duration.value
  audioEl.value.currentTime = newTime
  currentTime.value = newTime
}

// ===== RACCOURCIS CLAVIER =====
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
  <div class="min-h-screen bg-gray-50 flex flex-col items-center py-12 px-4">
    <div class="w-full max-w-4xl rounded-2xl shadow-lg bg-white p-6">
      <!-- Header -->
      <div class="grid grid-cols-1 md:grid-cols-[1.2fr_1fr] gap-6 items-center mb-6">
        <img
          :src="album?.cover_url"
          alt="Cover album"
          class="w-full aspect-square rounded-2xl object-cover bg-gray-100"
        />
        <div class="flex flex-col justify-center">
          <h1 class="text-3xl font-extrabold tracking-tight mb-2">Muso</h1>
          <p class="text-gray-700">
            <span class="font-semibold">Album :</span>
            <span class="italic">{{ album?.title || '' }}</span>
          </p>
          <p v-if="album?.release_year" class="text-gray-500">Sortie : {{ album.release_year }}</p>
        </div>
      </div>

      <!-- États -->
      <div v-if="isLoading" class="text-gray-500">Chargement…</div>
      <div v-else-if="errorMsg" class="text-red-600">{{ errorMsg }}</div>

      <!-- Player global (si piste active) -->
      <div v-if="activeTrack" class="mb-6">
        <div class="rounded-xl border bg-gray-50 p-4">
          <div class="flex items-center justify-between mb-2">
            <p class="font-medium text-gray-900 truncate">▶ {{ activeTrack.title }}</p>
            <div class="text-sm tabular-nums text-gray-600">
              {{ formatTime(currentTime) }} / {{ formatTime(duration) }}
            </div>
          </div>

          <div
            class="h-2 w-full bg-gray-200 rounded-full cursor-pointer"
            @click="onProgressClick"
            title="Cliquer pour naviguer"
          >
            <div
              class="h-2 bg-emerald-600 rounded-full"
              :style="{ width: `${progress * 100}%` }"
            />
          </div>

          <div class="mt-3 flex gap-2">
            <button
              @click="playPrev"
              class="rounded border px-3 py-1 text-sm hover:shadow active:scale-95"
            >⏮︎ Préc</button>

            <button
              @click="isPlaying ? pause() : (activeTrack ? playTrack(activeTrack) : null)"
              class="rounded border px-3 py-1 text-sm hover:shadow active:scale-95"
            >{{ isPlaying ? 'Pause' : 'Play' }}</button>

            <button
              @click="playNext"
              class="rounded border px-3 py-1 text-sm hover:shadow active:scale-95"
            >⏭︎ Suiv</button>

            <span class="ml-auto text-xs text-gray-500">Raccourcis : Espace, ←, →</span>
          </div>
        </div>
      </div>

      <!-- Liste des pistes -->
      <ul v-if="album && album.tracks" class="divide-y divide-gray-100">
        <li
          v-for="t in album.tracks"
          :key="t.id"
          class="flex items-center gap-4 py-3 px-2 rounded-lg hover:bg-gray-50"
          :class="isActive(t) ? 'bg-emerald-100' : ''"
        >
          <div class="w-8 text-right text-gray-400">{{ t.track_number }}</div>

          <div class="flex-1">
            <p class="font-medium text-gray-900 leading-tight">{{ t.title }}</p>
            <p class="text-xs text-gray-500">Muso</p>
          </div>

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

    <!-- Lecteur audio global caché -->
    <audio ref="audioEl" class="hidden"></audio>
  </div>
</template>
