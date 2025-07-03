<template>
  <div class="message-box">
    <h1>{{ message }}</h1>
  </div>
</template>

<script setup>
  import { ref } from "vue";
  // déclaration de la constante du h1 message dans le template
  const message = ref('Hello Ugo !  Tout semble fonctionner');
</script>
<style scoped>
  .message-box {
    background-color: #f0f9ff;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 20px;
    text-align: center;
    font-family: sans-serif;
  }

</style>
