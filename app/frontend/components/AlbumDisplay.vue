<script setup>
// ===== Imports Vue =====
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'  // on importe l'API réactive et les hooks

// ===== ÉTAT GÉNÉRAL =====
const album = ref(null)            // contiendra l'album avec ses pistes
const isLoading = ref(true)        // indicateur de chargement
const errorMsg = ref(null)         // message d'erreur éventuel

// ===== PLAYER GLOBAL (un seul <audio>) =====
const audioEl = ref(null)          // référence vers l'élément <audio> caché
const currentTrackId = ref(null)   // id de la piste active (sélectionnée)
const isPlaying = ref(false)       // true si le player est en lecture
const currentTime = ref(0)         // temps courant (en secondes)
const duration = ref(0)            // durée totale de la piste (en secondes)

// Fonction utilitaire : formate un nombre de secondes en mm:ss
const formatTime = (sec) => {
  if (!sec || sec === Infinity) return '0:00'     // gère les cas indéfinis
  const m = Math.floor(sec / 60)                  // minutes entières
  const s = Math.floor(sec % 60).toString().padStart(2, '0')  // secondes sur 2 chiffres
  return `${m}:${s}`                              // retourne le format "m:ss"
}

// Calcul réactif : ratio d'avancement 0..1 pour la barre de progression
const progress = computed(() => {
  if (!duration.value) return 0
  return Math.min(1, Math.max(0, currentTime.value / duration.value))
})

// Calcul réactif : renvoie l'objet piste actif (ou null)
const activeTrack = computed(() => {
  if (!album.value || !currentTrackId.value) return null
  return album.value.tracks.find(t => t.id === currentTrackId.value) || null
})

// ===== CHARGEMENT DE L'ALBUM =====
onMounted(async () => {
  try {
    // 1) on récupère la liste des albums
    const listRes = await fetch('/api/v1/albums')      // appelle l'endpoint index
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status} (index)`)
    const albums = await listRes.json()                // parse le JSON

    // 2) on choisit "Simone" si présent, sinon le premier de la liste
    const target = albums.find(a => a.title === 'Simone') || albums[0]
    if (!target) throw new Error('Aucun album')

    // 3) on récupère le détail de l'album choisi (avec les pistes)
    const showRes = await fetch(`/api/v1/albums/${target.id}`)
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status} (show)`)
    album.value = await showRes.json()                 // on stocke l'album
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}`  // message en cas d’erreur
  } finally {
    isLoading.value = false                           // fin du chargement dans tous les cas
  }

  // On branche les événements du lecteur audio global une fois le composant monté
  if (audioEl.value) {
    audioEl.value.addEventListener('ended', onEnded)  // quand la piste se termine
    audioEl.value.addEventListener('pause', () => { isPlaying.value = false }) // met à jour l'état
    audioEl.value.addEventListener('play',  () => { isPlaying.value = true  }) // met à jour l'état
    audioEl.value.addEventListener('timeupdate', () => {                      // avance de lecture
      currentTime.value = audioEl.value.currentTime || 0                      // temps courant
      duration.value = audioEl.value.duration || 0                            // durée totale
    })
    audioEl.value.addEventListener('loadedmetadata', () => {                  // métadonnées chargées
      duration.value = audioEl.value.duration || 0                            // initialise la durée
    })
  }

  // On ajoute des raccourcis clavier globaux (Espace / ← / →)
  window.addEventListener('keydown', onKeyDown)
})

// Nettoyage des listeners quand le composant est détruit
onBeforeUnmount(() => {
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded)
  window.removeEventListener('keydown', onKeyDown)
})

// ===== ACTIONS PLAYER =====

// Lance la lecture d'une piste donnée
const playTrack = async (track) => {
  if (!audioEl.value) return
  if (currentTrackId.value !== track.id) {   // si on change de piste
    currentTrackId.value = track.id          // mémorise l'id
    audioEl.value.src = track.audio_url      // charge la nouvelle source audio
    currentTime.value = 0                    // remet le curseur au début
  }
  try {
    await audioEl.value.play()               // essaie de jouer
    isPlaying.value = true                   // met à jour l'état
  } catch (e) {
    console.warn('Lecture bloquée :', e)     // par ex. blocage d’autoplay
    isPlaying.value = false
  }
}

// Met en pause la lecture
const pause = () => {
  if (!audioEl.value) return
  audioEl.value.pause()                      // met en pause
  isPlaying.value = false                    // met à jour l'état
}

// Bascule Play/Pause pour une piste
const toggle = (t) => {
  (currentTrackId.value === t.id && isPlaying.value) ? pause() : playTrack(t)
}

// Passe à la piste suivante (si elle existe)
const playNext = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)  // index de la piste active
  const next = list[idx + 1]                                      // piste suivante
  if (next) playTrack(next)                                       // joue la suivante si elle existe
}

// Passe à la piste précédente (si elle existe)
const playPrev = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)  // index de la piste active
  const prev = list[idx - 1]                                      // piste précédente
  if (prev) playTrack(prev)                                       // joue la précédente si elle existe
}

// Callback quand la piste se termine : enchaîne la suivante, sinon stoppe
const onEnded = () => {
  if (!album.value) return
  const list = album.value.tracks
  const idx = list.findIndex(t => t.id === currentTrackId.value)
  const next = list[idx + 1]
  next ? playTrack(next) : (isPlaying.value = false, currentTrackId.value = null)
}

// Utilitaires d'état pour la liste
const isActive = (t) => currentTrackId.value === t.id                  // true si la ligne est la piste active
const isActiveAndPlaying = (t) => isActive(t) && isPlaying.value       // true si active ET en lecture

// ===== BARRE DE PROGRESSION =====

// Seek sur clic dans la barre de progression (sticky bar)
const onProgressClick = (e) => {
  if (!audioEl.value || !duration.value) return
  const rect = e.currentTarget.getBoundingClientRect()     // récupère la boîte englobante
  const x = e.clientX - rect.left                           // position X du clic dans la barre
  const ratio = Math.min(1, Math.max(0, x / rect.width))    // ramène entre 0 et 1
  const newTime = ratio * duration.value                    // convertit en secondes
  audioEl.value.currentTime = newTime                       // applique au lecteur
  currentTime.value = newTime                               // met à jour l'état
}

// ===== RACCOURCIS CLAVIER =====

// Espace = Play/Pause ; → = suivant ; ← = précédent
const onKeyDown = (e) => {
  if (['Space', 'ArrowRight', 'ArrowLeft'].includes(e.code)) e.preventDefault() // évite le scroll
  if (e.code === 'Space') {
    if (activeTrack.value) {
      isPlaying.value ? pause() : playTrack(activeTrack.value)
    } else if (album.value?.tracks?.length) {
      playTrack(album.value.tracks[0])   // si rien n'est chargé, lance la première piste
    }
  } else if (e.code === 'ArrowRight') {
    playNext()
  } else if (e.code === 'ArrowLeft') {
    playPrev()
  }
}
</script>

<template>
  <!-- Conteneur principal avec padding-bottom pour ne pas masquer le contenu sous la barre sticky -->
  <div class="min-h-screen bg-gray-50 flex flex-col items-center py-12 px-4 pb-28">
    <!-- Carte contenu album -->
    <div class="w-full max-w-4xl rounded-2xl shadow-lg bg-white p-6">
      <!-- Header (cover + infos) -->
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

      <!-- États (chargement/erreur) -->
      <div v-if="isLoading" class="text-gray-500">Chargement…</div>
      <div v-else-if="errorMsg" class="text-red-600">{{ errorMsg }}</div>

      <!-- Liste des pistes -->
      <ul v-else-if="album && album.tracks" class="divide-y divide-gray-100">
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

    <!-- ===== Sticky Player (barre fixe en bas) ===== -->
    <div
      v-if="activeTrack"
      class="fixed inset-x-0 bottom-0 z-50 border-t bg-white/80 backdrop-blur supports-[backdrop-filter]:bg-white/60"
    >
      <div class="max-w-4xl mx-auto px-4 py-3">
        <div class="flex items-center gap-4">
          <!-- Infos piste -->
          <div class="min-w-0">
            <p class="font-medium text-gray-900 truncate">{{ activeTrack.title }}</p>
            <p class="text-xs text-gray-500 truncate">Muso — {{ album?.title }}</p>
          </div>

          <!-- Contrôles -->
          <div class="flex items-center gap-2 ml-auto">
            <button
              @click="playPrev"
              class="rounded border px-3 py-1 text-sm hover:shadow active:scale-95"
            >⏮︎</button>

            <button
              @click="isPlaying ? pause() : (activeTrack ? playTrack(activeTrack) : null)"
              class="rounded-full border px-4 py-2 text-sm font-semibold hover:shadow active:scale-95"
              :class="isPlaying ? 'bg-emerald-600 text-white border-emerald-600' : 'bg-white text-gray-700 border-gray-300'"
            >
              {{ isPlaying ? 'Pause' : 'Play' }}
            </button>

            <button
              @click="playNext"
              class="rounded border px-3 py-1 text-sm hover:shadow active:scale-95"
            >⏭︎</button>
          </div>
        </div>

        <!-- Barre de progression cliquable -->
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
    <!-- ===== /Sticky Player ===== -->
  </div>
</template>
