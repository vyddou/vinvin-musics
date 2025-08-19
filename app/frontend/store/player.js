// @ts-nocheck
import { reactive } from 'vue'

export const playerStore = reactive({
  queue: [],             // liste de pistes à jouer
  currentIndex: -1,      // index de la piste en cours
  isPlaying: false,

  // ajoute une piste en fin de file et la lance si rien n'est en cours
  enqueue(track) {
    console.log('Enqueueing', track.title)
    this.queue.push(track)
    if (!this.isPlaying) {
      this.playNext()
    }
  },

  // passe à la piste suivante
  playNext() {
    if (this.queue.length === 0) {
      this.currentIndex = -1
      this.isPlaying = false
      return
    }
    this.currentIndex = 0
    this.isPlaying = true
    console.log('Playing next', this.currentIndex, this.queue[0].title)
  },

  // retire la piste terminée et relance
  onTrackEnded() {
    this.queue.shift()
    this.playNext()
  }
})
