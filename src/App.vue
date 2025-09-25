<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import AppLayout from '@/layout/AppLayout.vue'

const route = useRoute()
const { initializeAuth, setupAuthListener, currentUser } = useAuth()

// Initialize authentication on app mount
onMounted(async () => {
  await initializeAuth()
  setupAuthListener()
})

// Watch for route changes to enforce authentication
watch(route, (newRoute) => {
  if (!currentUser.value && newRoute.path !== '/login') {
  }
})
</script>

<template>
  <AppLayout>
    <RouterView />
  </AppLayout>
</template>

