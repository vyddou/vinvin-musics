// === Dark mode auto (suivant le système) ===
// si l'OS est en dark → ajoute 'dark' sur <html>
const mq = window.matchMedia('(prefers-color-scheme: dark)')            // écoute les prefs système
const applyDark = () => document.documentElement.classList.toggle('dark', mq.matches) // toggle classe 'dark' sur <html>
applyDark()                                                             // applique à l'init
mq.addEventListener('change', applyDark)                                // réagit si l’utilisateur change son thème

import { createApp } from 'vue'
import AlbumDisplay from '../components/AlbumDisplay.vue'

createApp(AlbumDisplay).mount('#app')
