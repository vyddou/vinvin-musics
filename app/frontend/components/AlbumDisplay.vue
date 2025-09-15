<script setup>
// ===== Imports Vue & icônes =====
import { ref, onMounted, onBeforeUnmount, computed, nextTick } from 'vue' // API composition
import { Play, Pause, SkipBack, SkipForward } from 'lucide-vue-next'      // Icônes du player

// ===== État global du composant =====
const album = ref(null)            // album chargé depuis l’API
const isLoading = ref(true)        // affichage d’un loader pendant la requête
const errorMsg = ref(null)         // message d’erreur éventuel

const audioEl = ref(null)          // <audio> HTML
const currentTrackId = ref(null)   // id de la piste en cours
const isPlaying = ref(false)       // état de lecture
const currentTime = ref(0)         // temps courant (s)
const duration = ref(0)            // durée totale (s)

// ===== Drag progress =====
const isDragging = ref(false)      // true quand on glisse la poignée
const progressWrap = ref(null)     // ref vers le conteneur de la barre

// --- format mm:ss (ex: 2:09)
const formatTime = (sec) => {
  if (!sec || sec === Infinity) return '0:00'
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

// --- ratio 0..1 pour la barre de progression
const progress = computed(() => {
  if (!duration.value) return 0
  return Math.min(1, Math.max(0, currentTime.value / duration.value))
})

// --- piste active (objet piste) à partir de l’id courant
const activeTrack = computed(() => {
  if (!album.value || !currentTrackId.value) return null
  return album.value.tracks.find(t => t.id === currentTrackId.value) || null
})

// --- helpers d’état pour la liste
const isActive = (track) => currentTrackId.value === track.id
const isActiveAndPlaying = (track) => currentTrackId.value === track.id && isPlaying.value

// ===== Chargement de l’album =====
onMounted(async () => {
  try {
    // 1) liste des albums
    const listRes = await fetch('/api/v1/albums')
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status} (index)`)
    const albums = await listRes.json()

    // 2) cible : album "Simone" sinon premier de la liste
    const target = albums.find(a => a.title === 'Simone') || albums[0]
    if (!target) throw new Error('Aucun album')

    // 3) show album + pistes
    const showRes = await fetch(`/api/v1/albums/${target.id}`)
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status} (show)`)
    album.value = await showRes.json()
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}`
  } finally {
    isLoading.value = false                     // stop loader
    await nextTick()                            // s’assure que <audio> existe
    setupAudioEvents()                          // branche les events audio
  }

  // --- écoute globale clavier + drag
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('mousemove', onDragMove)
  window.addEventListener('mouseup', onDragEnd)
  window.addEventListener('touchmove', onDragMove, { passive: false })
  window.addEventListener('touchend', onDragEnd)
})

// ===== Nettoyage des listeners =====
onBeforeUnmount(() => {
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded)
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('mousemove', onDragMove)
  window.removeEventListener('mouseup', onDragEnd)
  window.removeEventListener('touchmove', onDragMove)
  window.removeEventListener('touchend', onDragEnd)
})

// ===== Événements audio =====
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
    // on ne bouge pas le curseur durant le drag
    if (!isDragging.value) {
      currentTime.value = audioEl.value.currentTime || 0
    }
    duration.value = audioEl.value.duration || 0
  })
  audioEl.value.addEventListener('loadedmetadata', () => {
    duration.value = audioEl.value.duration || 0
  })
}

// ===== Actions player =====
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

// ===== Clic dans la barre de progression =====
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
  updateTimeFromEvent(e, /*previewOnly*/ true)
}
const onDragEnd = (e) => {
  if (!isDragging.value || !audioEl.value) return
  updateTimeFromEvent(e)
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

// ===== Raccourcis clavier =====
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
  <!--
    Racine plate :
    - pas de shadow/border ici (la carte sombre vient de la page home)
    - pb-28 pour laisser la place au player sticky
  -->
  <div class="w-full pb-28">
    <!-- ÉTATS DE CHARGEMENT / ERREUR -->
    <div v-if="isLoading" class="text-gray-300">Chargement…</div>
    <div v-else-if="errorMsg" class="text-red-400">{{ errorMsg }}</div>
    <div v-else-if="!album" class="text-gray-300">Aucun album trouvé.</div>

    <!-- CONTENU PRINCIPAL -->
    <div v-else>
      <!-- HEADER ALBUM -->
      <div class="grid grid-cols-1 md:grid-cols-[1.2fr_1fr] gap-6 items-center mb-6">
        <!-- cover -->
        <img
          :src="album.cover_url"
          alt="Cover album"
          class="w-full aspect-square rounded-2xl object-cover"
        />
        <!-- infos -->
        <div class="flex flex-col justify-center">
          <h1 class="text-3xl font-extrabold tracking-tight mb-2">Muso</h1>
          <p class="opacity-90">
            <span class="font-semibold">Album :</span> <span class="italic">{{ album.title }}</span>
          </p>
          <p v-if="album.release_year" class="opacity-70">Sortie : {{ album.release_year }}</p>
        </div>
      </div>

      <!-- LISTE DES PISTES (aucun divide/border/hover dur) -->
      <ul v-if="album.tracks && album.tracks.length">
        <li
          v-for="t in album.tracks"
          :key="t.id"
          class="flex items-center gap-4 py-3 px-2 rounded-lg hover:bg-white/5"
          :class="isActive(t) ? 'bg-emerald-900/30' : ''"
        >
          <!-- numéro -->
          <div class="w-8 text-right opacity-60">{{ t.track_number }}</div>

          <!-- titre -->
          <div class="flex-1 min-w-0">
            <p class="font-medium leading-tight truncate">{{ t.title }}</p>
            <p class="text-xs opacity-70 truncate">Muso</p>
          </div>

          <!-- bouton play/pause (sans border/shadow) -->
          <button
            @click="toggle(t)"
            class="inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold active:scale-95 transition"
            :class="isActiveAndPlaying(t) ? 'bg-emerald-600 text-white' : 'bg-white/10 text-white'"
            aria-label="Play/Pause"
          >
            <Pause v-if="isActiveAndPlaying(t)" :size="18" />
            <Play v-else :size="18" />
            <span class="sr-only">Play/Pause</span>
          </button>
        </li>
      </ul>

      <div v-else class="text-gray-300">Aucune piste dans cet album.</div>
    </div>
  </div>

  <!-- ÉLÉMENT AUDIO (caché) -->
  <audio ref="audioEl" class="hidden"></audio>

  <!-- PLAYER COLLANT EN BAS (translucide comme la nav) -->
  <div
    v-if="activeTrack"
    class="fixed inset-x-0 bottom-0 z-50 bg-gray-900/70 backdrop-blur"
    style="padding-bottom: env(safe-area-inset-bottom);"
  >
    <div class="max-w-4xl mx-auto px-4 py-3 text-white">
      <div class="flex items-center gap-3">
        <!-- mini cover -->
        <img
          :src="activeTrack.cover_url || album.cover_url"
          alt=""
          class="w-10 h-10 rounded-md object-cover"
        />

        <!-- titre piste -->
        <div class="min-w-0">
          <p class="font-medium truncate">{{ activeTrack.title }}</p>
          <p class="text-xs opacity-80 truncate">Muso — {{ album.title }}</p>
        </div>

        <!-- contrôles -->
        <div class="flex items-center gap-2 ml-auto">
          <button
            @click="playPrev"
            class="rounded-full w-9 h-9 flex items-center justify-center active:scale-95 bg-white/10 text-white"
            aria-label="Précédent"
          >
            <SkipBack :size="16" />
          </button>

          <button
            @click="isPlaying ? pause() : (activeTrack ? playTrack(activeTrack) : null)"
            class="rounded-full w-10 h-10 flex items-center justify-center font-semibold active:scale-95"
            :class="isPlaying ? 'bg-emerald-600 text-white' : 'bg-white/10 text-white'"
            aria-label="Play/Pause"
          >
            <Pause v-if="isPlaying" :size="18" />
            <Play v-else :size="18" />
          </button>

          <button
            @click="playNext"
            class="rounded-full w-9 h-9 flex items-center justify-center active:scale-95 bg-white/10 text-white"
            aria-label="Suivant"
          >
            <SkipForward :size="16" />
          </button>
        </div>
      </div>

      <!-- barre de progression (sans border/shadow) -->
      <div class="mt-2">
        <div class="flex items-center gap-3">
          <span class="text-xs tabular-nums opacity-80">{{ formatTime(currentTime) }}</span>

          <div
            ref="progressWrap"
            class="flex-1 h-2 bg-white/20 rounded-full cursor-pointer relative select-none"
            @mousedown="onDragStart"
            @touchstart="onDragStart"
            @click="onProgressClick"
          >
            <!-- progression -->
            <div class="h-2 bg-emerald-500 rounded-full" :style="{ width: `${progress * 100}%` }"></div>

            <!-- poignée -->
            <div
              class="absolute -top-1.5 h-5 w-5 rounded-full bg-white"
              :style="{ left: `calc(${progress * 100}% - 10px)` }"
            />
          </div>

          <span class="text-xs tabular-nums opacity-80">{{ formatTime(duration) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
