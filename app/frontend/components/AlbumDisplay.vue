<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'

const album = ref(null)
const isLoading = ref(true)
const errorMsg = ref(null)

const audioEl = ref(null)
const currentTrackId = ref(null)
const isPlaying = ref(false)

onMounted(async () => {
  try {
    // 1) on récupère la liste des albums
    const listRes = await fetch('/api/v1/albums')
    if (!listRes.ok) throw new Error(`HTTP ${listRes.status} (index)`)
    const albums = await listRes.json()

    // 2) on cherche "Simone", sinon on prend le premier
    const target = albums.find(a => a.title === 'Simone') || albums[0]
    if (!target) throw new Error('Aucun album trouvé')

    // 3) on charge le détail (avec les tracks)
    const showRes = await fetch(`/api/v1/albums/${target.id}`)
    if (!showRes.ok) throw new Error(`HTTP ${showRes.status} (show)`)
    album.value = await showRes.json()
  } catch (e) {
    errorMsg.value = `Impossible de charger l’album : ${e}`
  } finally {
    isLoading.value = false
  }

  if (audioEl.value) {
    audioEl.value.addEventListener('ended', onEnded)
    audioEl.value.addEventListener('pause', () => { isPlaying.value = false })
    audioEl.value.addEventListener('play', () => { isPlaying.value = true })
  }
})

onBeforeUnmount(() => {
  if (audioEl.value) audioEl.value.removeEventListener('ended', onEnded)
})

const srcOf = (track) => track.audio_url
const playTrack = async (track) => {
  if (currentTrackId.value === track.id) {
    await audioEl.value.play()
    isPlaying.value = true
    return
  }
  currentTrackId.value = track.id
  audioEl.value.src = srcOf(track)
  try {
    await audioEl.value.play()
    isPlaying.value = true
  } catch (e) {
    console.warn('Lecture bloquée :', e)
    isPlaying.value = false
  }
}
const pause = () => { if (audioEl.value) { audioEl.value.pause(); isPlaying.value = false } }
const toggle = (track) => { (currentTrackId.value === track.id && isPlaying.value) ? pause() : playTrack(track) }
const onEnded = () => {
  if (!album.value) return
  const tracks = album.value.tracks
  const idx = tracks.findIndex(t => t.id === currentTrackId.value)
  const next = tracks[idx + 1]
  if (next) { playTrack(next) } else { isPlaying.value = false; currentTrackId.value = null }
}
const isActiveAndPlaying = (track) => currentTrackId.value === track.id && isPlaying.value
const isActive = (track) => currentTrackId.value === track.id
</script>


<template>
  <!-- Header global -->
  <div class="min-h-screen bg-gray-50 flex flex-col items-center py-10 px-4">
    <!-- Carte album -->
    <div class="w-full max-w-2xl rounded-2xl shadow-md bg-white p-6 mb-8">
      <!-- État chargement / erreur -->
      <div v-if="isLoading" class="text-gray-500">Chargement…</div>       <!-- message pendant fetch -->
      <div v-else-if="errorMsg" class="text-red-600">{{ errorMsg }}</div> <!-- message d'erreur -->

      <!-- Contenu album -->
      <div v-else>
        <!-- En-tête album -->
        <div class="flex items-center gap-4 mb-6">
          <img
            :src="album.cover_url"
            alt="cover album"
            class="w-24 h-24 rounded-xl shadow"
          /> <!-- pochette -->
          <div>
            <h2 class="text-2xl font-bold leading-tight">Muso</h2>        <!-- artiste -->
            <p class="text-gray-600">Album : <span class="italic">{{ album.title }}</span></p> <!-- titre -->
            <p class="text-sm text-gray-400" v-if="album.release_year">Sortie : {{ album.release_year }}</p> <!-- année -->
          </div>
        </div>

        <!-- Liste des pistes -->
        <ul class="divide-y divide-gray-100">
          <li
            v-for="track in album.tracks"
            :key="track.id"
            class="flex items-center gap-4 py-3 px-2 hover:bg-gray-50 rounded-lg"
            :class="{'bg-emerald-50': isActive(track)}"
          >
            <!-- numéro + titre -->
            <div class="w-8 text-right text-gray-400">{{ track.track_number }}</div> <!-- numéro -->
            <div class="flex-1">
              <p class="font-medium text-gray-800">{{ track.title }}</p>             <!-- titre piste -->
              <p class="text-xs text-gray-400">Muso</p>                               <!-- artiste -->
            </div>

            <!-- Bouton Play/Pause -->
            <button
              @click="toggle(track)"
              class="rounded-full border px-4 py-2 text-sm font-semibold transition
                     hover:shadow active:scale-95"
              :class="isActiveAndPlaying(track)
                      ? 'bg-emerald-600 text-white border-emerald-600'
                      : 'bg-white text-gray-700 border-gray-300'"
            >
              {{ isActiveAndPlaying(track) ? 'Pause' : 'Play' }}                      <!-- libellé dynamique -->
            </button>
          </li>
        </ul>
      </div>
    </div>

    <!-- Élément audio unique, invisible -->
    <audio ref="audioEl" class="hidden"></audio>                                     <!-- lecteur global -->
  </div>
</template>

<style scoped>
/* rien de particulier, tout est géré par Tailwind */
</style>
