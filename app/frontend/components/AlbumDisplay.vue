<script setup>
// ===== Vue + icônes =====
import { ref, onMounted, onBeforeUnmount, computed, nextTick } from 'vue'
import { Play, Pause, SkipBack, SkipForward } from 'lucide-vue-next'

// ===== État global =====
const album = ref(null)
const isLoading = ref(true)
const errorMsg = ref(null)

const audioEl = ref(null)
const currentTrackId = ref(null)
const isPlaying = ref(false)
const currentTime = ref(0)
const duration = ref(0)

// ===== Drag progress =====
const isDragging = ref(false)       // true quand on glisse la barre
const progressWrap = ref(null)      // ref vers le conteneur de la barre

// format mm:ss
const formatTime = (sec) => {
  if (!sec || sec === Infinity) return '0:00'
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

// ratio 0..1
const progress = computed(() => {
  if (!duration.value) return 0
  return Math.min(1, Math.max(0, currentTime.value / duration.value))
})

// piste active
const activeTrack = computed(() => {
  if (!album.value || !currentTrackId.value) return null
  return album.value.tracks.find(t => t.id === currentTrackId.value) || null
})

// helper d’état pour la liste
const isActive = (track) => currentTrackId.value === track.id
const isActiveAndPlaying = (track) => currentTrackId.value === track.id && isPlaying.value

// charge l’album
onMounted(async () => {
  try {
    const listRes = await fetch('/api/v1/albums')
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status} (index)`)
    const albums = await listRes.json()

    const target = albums.find(a => a.title === 'Simone') || albums[0]
    if (!target) throw new Error('Aucun album')

    const showRes = await fetch(`/api/v1/albums/${target.id}`)
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status} (show)`)
    album.value = await showRes.json()
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}`
  } finally {
    isLoading.value = false
    await nextTick()            // s’assure que <audio> est présent
    setupAudioEvents()          // branchement des events
  }

  // raccourcis clavier
  window.addEventListener('keydown', onKeyDown)
  // events globaux pour drag (souris + tactile)
  window.addEventListener('mousemove', onDragMove)
  window.addEventListener('mouseup', onDragEnd)
  window.addEventListener('touchmove', onDragMove, { passive: false })
  window.addEventListener('touchend', onDragEnd)
})

onBeforeUnmount(() => {
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded)
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('mousemove', onDragMove)
  window.removeEventListener('mouseup', onDragEnd)
  window.removeEventListener('touchmove', onDragMove)
  window.removeEventListener('touchend', onDragEnd)
})

// branche les events audio
const setupAudioEvents = () => {
  if (!audioEl.value) return
  audioEl.value.addEventListener('error', (e) => {
    console.error('Erreur audio:', e)
    errorMsg.value = 'Erreur de lecture audio'
    isPlaying.value = false
  })
  audioEl.value.addEventListener('ended', onEnded)
  audioEl.value.addEventListener('pause', () => { isPlaying.value = false })
  audioEl.value.addEventListener('play',  () => { isPlaying.value = true  })
  audioEl.value.addEventListener('timeupdate', () => {
    if (!isDragging.value) {                       // ne pas “sauter” pendant le drag
      currentTime.value = audioEl.value.currentTime || 0
    }
    duration.value = audioEl.value.duration || 0
  })
  audioEl.value.addEventListener('loadedmetadata', () => {
    duration.value = audioEl.value.duration || 0
  })
}

// actions player
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
const pause = () => { if (audioEl.value) audioEl.value.pause(); isPlaying.value = false }
const toggle = (t) => { (currentTrackId.value === t.id && isPlaying.value) ? pause() : playTrack(t) }

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

// seek par clic simple
const onProgressClick = (e) => {
  if (!audioEl.value || !duration.value) return
  const rect = e.currentTarget.getBoundingClientRect()
  const x = (e.clientX ?? e.touches?.[0]?.clientX) - rect.left
  const ratio = Math.min(1, Math.max(0, x / rect.width))
  const newTime = ratio * duration.value
  audioEl.value.currentTime = newTime
  currentTime.value = newTime
}

// ===== Drag & drop de la progress bar =====
const onDragStart = (e) => {
  if (!progressWrap.value || !duration.value) return
  isDragging.value = true
  e.preventDefault?.()
  updateTimeFromEvent(e)
}
const onDragMove = (e) => {
  if (!isDragging.value) return
  e.preventDefault?.()
  updateTimeFromEvent(e, /*previewOnly*/ true) // on bouge l’affichage sans toucher l’audio en temps réel
}
const onDragEnd = (e) => {
  if (!isDragging.value || !audioEl.value) return
  updateTimeFromEvent(e)                       // on fixe le temps final
  isDragging.value = false
}
const updateTimeFromEvent = (e, previewOnly = false) => {
  const rect = progressWrap.value.getBoundingClientRect()
  const clientX = e?.clientX ?? e?.touches?.[0]?.clientX ?? e?.changedTouches?.[0]?.clientX
  if (clientX == null) return
  const x = clientX - rect.left
  const ratio = Math.min(1, Math.max(0, x / rect.width))
  const newTime = ratio * (duration.value || 0)
  currentTime.value = newTime
  if (!previewOnly && audioEl.value) {
    audioEl.value.currentTime = newTime
  }
}

// raccourcis clavier
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
  <!-- container principal ; classes dark: activées si <html> a .dark -->
  <div class="min-h-screen bg-gray-50 dark:bg-neutral-900 flex flex-col items-center py-12 px-4 pb-28">
    <div class="w-full max-w-4xl rounded-2xl shadow-lg bg-white dark:bg-neutral-800 p-6">
      <div v-if="isLoading" class="text-gray-500 dark:text-gray-300">Chargement…</div>
      <div v-else-if="errorMsg" class="text-red-600 dark:text-red-400">{{ errorMsg }}</div>
      <div v-else-if="!album" class="text-gray-600 dark:text-gray-300">Aucun album trouvé.</div>

      <div v-else>
        <!-- header album -->
        <div class="grid grid-cols-1 md:grid-cols-[1.2fr_1fr] gap-6 items-center mb-6">
          <img :src="album.cover_url" alt="Cover album"
               class="w-full aspect-square rounded-2xl object-cover bg-gray-100 dark:bg-neutral-700" />
          <div class="flex flex-col justify-center">
            <h1 class="text-3xl font-extrabold tracking-tight mb-2 text-neutral-900 dark:text-white">Muso</h1>
            <p class="text-gray-700 dark:text-gray-200">
              <span class="font-semibold">Album :</span> <span class="italic">{{ album.title }}</span>
            </p>
            <p v-if="album.release_year" class="text-gray-500 dark:text-gray-400">Sortie : {{ album.release_year }}</p>
          </div>
        </div>

        <!-- liste des pistes -->
        <ul v-if="album.tracks && album.tracks.length" class="divide-y divide-gray-100 dark:divide-neutral-700">
          <li
            v-for="t in album.tracks"
            :key="t.id"
            class="flex items-center gap-4 py-3 px-2 rounded-lg hover:bg-gray-50 dark:hover:bg-neutral-750/50"
            :class="isActive(t) ? 'bg-emerald-100 dark:bg-emerald-900/30' : ''"
          >
            <div class="w-8 text-right text-gray-400">{{ t.track_number }}</div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-gray-900 dark:text-gray-100 leading-tight truncate">{{ t.title }}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400 truncate">Muso</p>
            </div>
            <button
              @click="toggle(t)"
              class="inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold border transition hover:shadow active:scale-95"
              :class="isActiveAndPlaying(t)
                ? 'bg-emerald-600 text-white border-emerald-600'
                : 'bg-white dark:bg-neutral-800 text-gray-700 dark:text-gray-100 border-gray-300 dark:border-neutral-600'"
              aria-label="Play/Pause"
            >
              <Pause v-if="isActiveAndPlaying(t)" :size="18" />
              <Play v-else :size="18" />
              <span class="sr-only">Play/Pause</span>
            </button>
          </li>
        </ul>

        <div v-else class="text-gray-500 dark:text-gray-300">Aucune piste dans cet album.</div>
      </div>
    </div>

    <!-- lecteur audio -->
    <audio ref="audioEl" class="hidden"></audio>

    <!-- STICKY PLAYER -->
    <div
      v-if="activeTrack"
      class="fixed inset-x-0 bottom-0 z-50 border-t bg-white/90 dark:bg-neutral-900/90 backdrop-blur
             supports-[backdrop-filter]:bg-white/70 supports-[backdrop-filter]:dark:bg-neutral-900/70"
      style="padding-bottom: env(safe-area-inset-bottom);"
    >
      <div class="max-w-4xl mx-auto px-4 py-3">
        <div class="flex items-center gap-3">
          <!-- mini cover -->
          <img :src="activeTrack.cover_url || album.cover_url" alt=""
               class="w-10 h-10 rounded-md object-cover bg-gray-100 dark:bg-neutral-700" />

          <div class="min-w-0">
            <p class="font-medium text-gray-900 dark:text-gray-100 truncate">{{ activeTrack.title }}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400 truncate">Muso — {{ album.title }}</p>
          </div>

          <div class="flex items-center gap-2 ml-auto">
            <button
              @click="playPrev"
              class="rounded-full border w-9 h-9 flex items-center justify-center hover:shadow active:scale-95
                     bg-white dark:bg-neutral-800 text-gray-700 dark:text-gray-100 border-gray-300 dark:border-neutral-600"
              aria-label="Précédent"
            >
              <SkipBack :size="16" />
            </button>

            <button
              @click="isPlaying ? pause() : (activeTrack ? playTrack(activeTrack) : null)"
              class="rounded-full border w-10 h-10 flex items-center justify-center font-semibold hover:shadow active:scale-95
                     "
              :class="isPlaying
                ? 'bg-emerald-600 text-white border-emerald-600'
                : 'bg-white dark:bg-neutral-800 text-gray-700 dark:text-gray-100 border-gray-300 dark:border-neutral-600'"
              aria-label="Play/Pause"
            >
              <Pause v-if="isPlaying" :size="18" />
              <Play v-else :size="18" />
            </button>

            <button
              @click="playNext"
              class="rounded-full border w-9 h-9 flex items-center justify-center hover:shadow active:scale-95
                     bg-white dark:bg-neutral-800 text-gray-700 dark:text-gray-100 border-gray-300 dark:border-neutral-600"
              aria-label="Suivant"
            >
              <SkipForward :size="16" />
            </button>
          </div>
        </div>

        <!-- barre de progression draggable -->
        <div class="mt-2">
          <div class="flex items-center gap-3">
            <span class="text-xs tabular-nums text-gray-600 dark:text-gray-300">{{ formatTime(currentTime) }}</span>

            <div
              ref="progressWrap"
              class="flex-1 h-2 bg-gray-200 dark:bg-neutral-700 rounded-full cursor-pointer relative select-none"
              @mousedown="onDragStart"
              @touchstart="onDragStart"
              @click="onProgressClick"
            >
              <div class="h-2 bg-emerald-600 rounded-full" :style="{ width: `${progress * 100}%` }"></div>
              <!-- poignée -->
              <div
                class="absolute -top-1.5 h-5 w-5 rounded-full border shadow
                       bg-white dark:bg-neutral-900 border-gray-300 dark:border-neutral-600"
                :style="{ left: `calc(${progress * 100}% - 10px)` }"
              />
            </div>

            <span class="text-xs tabular-nums text-gray-600 dark:text-gray-300">{{ formatTime(duration) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
