<template>
  <div class="flex justify-between items-center p-2 hover:bg-gray-100 rounded cursor-pointer">
    <span>{{ track.title }}</span>
    <button @click="playTrack">
      ▶️
    </button>
  </div>
</template>

<script setup>
import { playerStore } from '../store/player'
const props = defineProps({ track: Object })

function playTrack() {
  console.log('Play clicked for', props.track.title)   // debug
  playerStore.enqueue(props.track)
}
</script>
