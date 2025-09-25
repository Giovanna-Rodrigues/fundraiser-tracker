<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import AppSidebar from './AppSidebar.vue'
import AppMobileHeader from './AppMobileHeader.vue'

const route = useRoute()
const { isAuthenticated } = useAuth()
const sidebarCollapsed = ref(false)

const toggleSidebar = () => {
  sidebarCollapsed.value = !sidebarCollapsed.value
}
</script>

<template>
  <div class="app" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    <!-- Sidebar Navigation -->
    <AppSidebar
      v-if="isAuthenticated"
      :collapsed="sidebarCollapsed"
      @toggle="toggleSidebar"
    />

    <!-- Mobile Navigation -->
    <AppMobileHeader v-if="isAuthenticated" />

    <!-- Main Content -->
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background-color: #f8f9fa;
  color: #2c3e50;
}

.app {
  min-height: 100vh;
  display: flex;
}

/* ===== MAIN CONTENT ===== */
.main-content {
  flex: 1;
  margin-left: 280px;
  transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  min-height: 100vh;
  background: #f8f9fa;
}

.sidebar-collapsed .main-content {
  margin-left: 70px;
}

/* ===== RESPONSIVE DESIGN ===== */
@media (max-width: 1024px) {
  .main-content {
    margin-left: 0;
    padding-top: 60px;
  }
}
</style>