<script setup lang="ts">
import { RouterView, useRoute, useRouter } from 'vue-router'
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()
const menuVisible = ref(false)

const currentUser = ref<any>(null)
const isAuthenticated = computed(() => !!currentUser.value)

onMounted(async () => {
  const { data: { session } } = await supabase.auth.getSession()

  if (session?.user) {
    currentUser.value = {
      email: session.user.email,
      id: session.user.id
    }
    localStorage.setItem('user', JSON.stringify(currentUser.value))
  } else {
    const savedUser = localStorage.getItem('user')
    if (savedUser) {
      currentUser.value = JSON.parse(savedUser)
    }
  }

  if (!currentUser.value && route.path !== '/login') {
    router.push('/login')
  }
})

supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') {
    currentUser.value = null
    localStorage.removeItem('user')
    router.push('/login')
  } else if (session?.user) {
    currentUser.value = {
      email: session.user.email,
      id: session.user.id
    }
    localStorage.setItem('user', JSON.stringify(currentUser.value))
  }
})

watch(route, (newRoute) => {
  if (!currentUser.value && newRoute.path !== '/login') {
    router.push('/login')
  }
})

const toggleMenu = () => {
  menuVisible.value = !menuVisible.value
}

const logout = async () => {
  await supabase.auth.signOut()
  localStorage.removeItem('user')
  currentUser.value = null
  router.push('/login')
}

const menuItems = [
  { path: '/', label: 'Dashboard', icon: 'pi pi-home' },
  { path: '/orders', label: 'Novo Pedido', icon: 'pi pi-plus' },
  { path: '/kitchen', label: 'Cozinha', icon: 'pi pi-stopwatch' },
  { path: '/pathfinders', label: 'Desbravadores', icon: 'pi pi-users' },
  { path: '/products', label: 'Produtos', icon: 'pi pi-box' },
  { path: '/campaigns', label: 'Campanhas', icon: 'pi pi-flag' },
  { path: '/leaderboard', label: 'Ranking', icon: 'pi pi-trophy' },
  { path: '/cost-calculation', label: 'Custos', icon: 'pi pi-calculator' }
]
</script>

<template>
  <div class="app">
    <!-- Navigation Header -->
    <header class="nav-header">
      <div class="nav-container">
        <div class="nav-brand">
          <img src="/logo.jpeg" alt="Logo do Clube" class="brand-logo" />
          <span class="brand-text">Campanha Desbravadores</span>
        </div>

        <nav class="nav-menu" :class="{ active: menuVisible }" v-if="isAuthenticated">
          <RouterLink
            v-for="item in menuItems"
            :key="item.path"
            :to="item.path"
            class="nav-item"
            :class="{ active: route.path === item.path }"
            @click="menuVisible = false"
          >
            <i :class="item.icon"></i>
            <span>{{ item.label }}</span>
          </RouterLink>
        </nav>

        <div class="nav-actions" v-if="isAuthenticated">
          <button class="logout-btn" @click="logout" title="Sair">
            <i class="pi pi-sign-out"></i>
          </button>
        </div>

        <button class="menu-toggle" @click="toggleMenu" v-if="isAuthenticated">
          <i class="pi pi-bars"></i>
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main class="main-content">
      <RouterView />
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
  flex-direction: column;
}

.nav-header {
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 1000;
}

.nav-container {
  width: 100%;
  padding: 0 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 70px;
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.brand-logo {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

.brand-text {
  font-size: 1.25rem;
  font-weight: bold;
  color: #2c3e50;
}

.nav-menu {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  color: #6c757d;
  text-decoration: none;
  transition: all 0.2s ease;
  font-weight: 500;
}

.nav-item:hover {
  background-color: #f8f9fa;
  color: #2c3e50;
}

.nav-item.active {
  background-color: var(--primary-color, #ef7f47);
  color: white;
}

.nav-item i {
  font-size: 1rem;
}

.nav-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.logout-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  background: none;
  border: none;
  color: #6c757d;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 0.375rem;
  transition: all 0.2s ease;
}

.logout-btn:hover {
  background: #f8f9fa;
  color: #dc3545;
}

.menu-toggle {
  display: none;
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #2c3e50;
  cursor: pointer;
  padding: 0.5rem;
}

.main-content {
  flex: 1;
  padding: 0;
}

@media (max-width: 768px) {
  .nav-container {
    padding: 0 0.75rem;
  }

  .menu-toggle {
    display: block;
  }

  .nav-menu {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background: white;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    flex-direction: column;
    padding: 1rem;
    gap: 0.25rem;
    transform: translateY(-10px);
    opacity: 0;
    visibility: hidden;
    transition: all 0.2s ease;
  }

  .nav-menu.active {
    transform: translateY(0);
    opacity: 1;
    visibility: visible;
  }

  .nav-item {
    width: 100%;
    justify-content: flex-start;
    padding: 0.875rem 1rem;
  }

  .brand-text {
    font-size: 1rem;
  }
}

@media (max-width: 480px) {
  .nav-container {
    padding: 0 0.5rem;
    height: 60px;
  }

  .brand-logo {
    width: 32px;
    height: 32px;
  }

  .brand-text {
    font-size: 0.875rem;
  }

  .nav-menu {
    padding: 0.75rem;
  }

  .nav-item {
    padding: 0.75rem;
    font-size: 0.875rem;
  }
}
</style>
