<script setup lang="ts">
import { RouterView, useRoute, useRouter } from 'vue-router'
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()
const menuVisible = ref(false)
const sidebarCollapsed = ref(false)

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

const toggleSidebar = () => {
  sidebarCollapsed.value = !sidebarCollapsed.value
}

const logout = async () => {
  await supabase.auth.signOut()
  localStorage.removeItem('user')
  currentUser.value = null
  router.push('/login')
}

const menuSections = [
  {
    title: 'Operações',
    icon: 'pi pi-briefcase',
    items: [
      { path: '/', label: 'Dashboard', icon: 'pi pi-home' },
      { path: '/orders', label: 'Novo Pedido', icon: 'pi pi-plus' },
      { path: '/kitchen', label: 'Cozinha', icon: 'pi pi-stopwatch' }
    ]
  },
  {
    title: 'Gestão',
    icon: 'pi pi-cog',
    items: [
      { path: '/pathfinders', label: 'Desbravadores', icon: 'pi pi-users' },
      { path: '/products', label: 'Produtos', icon: 'pi pi-box' },
      { path: '/campaigns', label: 'Campanhas', icon: 'pi pi-flag' }
    ]
  },
  {
    title: 'Relatórios',
    icon: 'pi pi-chart-bar',
    items: [
      { path: '/leaderboard', label: 'Ranking', icon: 'pi pi-trophy' },
      { path: '/cost-calculation', label: 'Custos', icon: 'pi pi-calculator' }
    ]
  }
]
</script>

<template>
  <div class="app" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    <!-- Sidebar Navigation -->
    <aside class="sidebar" v-if="isAuthenticated" :class="{ collapsed: sidebarCollapsed }">
      <!-- Sidebar Header -->
      <div class="sidebar-header">
        <div class="brand" v-if="!sidebarCollapsed">
          <img src="/logo.jpeg" alt="Logo do Clube" class="brand-logo" />
          <div class="brand-info">
            <span class="brand-title">Campanha</span>
            <span class="brand-subtitle">Desbravadores</span>
          </div>
        </div>
        <button class="sidebar-toggle" @click="toggleSidebar">
          <i class="pi" :class="sidebarCollapsed ? 'pi-angle-right' : 'pi-angle-left'"></i>
        </button>
      </div>

      <!-- Navigation Menu -->
      <nav class="sidebar-nav">
        <div v-for="section in menuSections" :key="section.title" class="nav-section">
          <div class="section-header" v-if="!sidebarCollapsed">
            <i :class="section.icon"></i>
            <span>{{ section.title }}</span>
          </div>
          <div class="section-divider" v-else></div>

          <ul class="section-items">
            <li v-for="item in section.items" :key="item.path">
              <RouterLink
                :to="item.path"
                class="nav-item"
                :class="{ active: route.path === item.path }"
                :title="sidebarCollapsed ? item.label : ''"
              >
                <i :class="item.icon"></i>
                <span v-if="!sidebarCollapsed">{{ item.label }}</span>
              </RouterLink>
            </li>
          </ul>
        </div>
      </nav>

      <!-- User Section -->
      <div class="sidebar-footer">
        <div class="user-info" v-if="currentUser">
          <div class="user-avatar">
            <i class="pi pi-user"></i>
          </div>
          <div class="user-details" v-if="!sidebarCollapsed">
            <span class="user-email">{{ currentUser.email }}</span>
            <button class="logout-link" @click="logout">
              <i class="pi pi-sign-out"></i>
              Sair
            </button>
          </div>
          <button v-else class="logout-btn-collapsed" @click="logout" title="Sair">
            <i class="pi pi-sign-out"></i>
          </button>
        </div>
      </div>
    </aside>

    <!-- Mobile Navigation -->
    <header class="mobile-header" v-if="isAuthenticated">
      <div class="mobile-container">
        <div class="mobile-brand">
          <img src="/logo.jpeg" alt="Logo do Clube" class="brand-logo" />
          <span class="brand-text">Campanha Desbravadores</span>
        </div>
        <button class="mobile-menu-toggle" @click="toggleMenu">
          <i class="pi pi-bars"></i>
        </button>
      </div>

      <!-- Mobile Menu Overlay -->
      <div class="mobile-menu-overlay" :class="{ active: menuVisible }" @click="menuVisible = false">
        <nav class="mobile-menu" @click.stop>
          <div class="mobile-menu-header">
            <div class="mobile-user-info">
              <div class="user-avatar">
                <i class="pi pi-user"></i>
              </div>
              <span class="user-email">{{ currentUser?.email }}</span>
            </div>
            <button class="mobile-menu-close" @click="menuVisible = false">
              <i class="pi pi-times"></i>
            </button>
          </div>

          <div class="mobile-menu-content">
            <div v-for="section in menuSections" :key="section.title" class="mobile-section">
              <div class="mobile-section-header">
                <i :class="section.icon"></i>
                <span>{{ section.title }}</span>
              </div>
              <ul class="mobile-section-items">
                <li v-for="item in section.items" :key="item.path">
                  <RouterLink
                    :to="item.path"
                    class="mobile-nav-item"
                    :class="{ active: route.path === item.path }"
                    @click="menuVisible = false"
                  >
                    <i :class="item.icon"></i>
                    <span>{{ item.label }}</span>
                  </RouterLink>
                </li>
              </ul>
            </div>
          </div>

          <div class="mobile-menu-footer">
            <button class="mobile-logout-btn" @click="logout">
              <i class="pi pi-sign-out"></i>
              Sair
            </button>
          </div>
        </nav>
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
}

/* ===== SIDEBAR LAYOUT ===== */
.sidebar {
  width: 280px;
  background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%);
  color: white;
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  z-index: 1000;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
}

.sidebar.collapsed {
  width: 70px;
}

.sidebar-collapsed .main-content {
  margin-left: 70px;
}

/* ===== SIDEBAR HEADER ===== */
.sidebar-header {
  padding: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  min-height: 80px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.brand-logo {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid rgba(255, 255, 255, 0.2);
}

.brand-info {
  display: flex;
  flex-direction: column;
}

.brand-title {
  font-size: 1.1rem;
  font-weight: bold;
  line-height: 1.2;
}

.brand-subtitle {
  font-size: 0.8rem;
  opacity: 0.8;
}

.sidebar-toggle {
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.sidebar-toggle:hover {
  background: rgba(255, 255, 255, 0.2);
}

/* ===== SIDEBAR NAVIGATION ===== */
.sidebar-nav {
  flex: 1;
  padding: 1rem 0;
  overflow-y: auto;
}

.nav-section {
  margin-bottom: 2rem;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0 1.5rem 0.5rem 1.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  opacity: 0.7;
}

.section-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.1);
  margin: 0 1rem 1rem 1rem;
}

.section-items {
  list-style: none;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1.5rem;
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  transition: all 0.2s ease;
  border-radius: 0;
  position: relative;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.nav-item.active {
  background: linear-gradient(90deg, rgba(239, 127, 71, 0.2), transparent);
  color: #ef7f47;
  border-right: 3px solid #ef7f47;
}

.nav-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: #ef7f47;
}

.nav-item i {
  font-size: 1.1rem;
  min-width: 20px;
}

.sidebar.collapsed .nav-item {
  justify-content: center;
  padding: 0.875rem 0;
}

/* ===== SIDEBAR FOOTER ===== */
.sidebar-footer {
  padding: 1.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.user-avatar {
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
}

.user-details {
  flex: 1;
  min-width: 0;
}

.user-email {
  display: block;
  font-size: 0.875rem;
  opacity: 0.9;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-bottom: 0.25rem;
}

.logout-link {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.8rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  transition: color 0.2s ease;
}

.logout-link:hover {
  color: #ef7f47;
}

.logout-btn-collapsed {
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.logout-btn-collapsed:hover {
  background: rgba(239, 127, 71, 0.2);
  color: #ef7f47;
}

/* ===== MAIN CONTENT ===== */
.main-content {
  flex: 1;
  margin-left: 280px;
  transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  min-height: 100vh;
  background: #f8f9fa;
}

/* ===== MOBILE NAVIGATION ===== */
.mobile-header {
  display: none;
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1100;
  height: 60px;
}

.mobile-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1rem;
  height: 100%;
}

.mobile-brand {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.mobile-brand .brand-logo {
  width: 32px;
  height: 32px;
  border: none;
}

.brand-text {
  font-size: 1rem;
  font-weight: bold;
  color: #2c3e50;
}

.mobile-menu-toggle {
  background: none;
  border: none;
  color: #2c3e50;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 0.375rem;
  transition: background 0.2s ease;
}

.mobile-menu-toggle:hover {
  background: #f8f9fa;
}

.mobile-menu-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  z-index: 1200;
  opacity: 0;
  visibility: hidden;
  transition: all 0.3s ease;
}

.mobile-menu-overlay.active {
  opacity: 1;
  visibility: visible;
}

.mobile-menu {
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  width: 300px;
  background: white;
  display: flex;
  flex-direction: column;
  transform: translateX(-100%);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.mobile-menu-overlay.active .mobile-menu {
  transform: translateX(0);
}

.mobile-menu-header {
  padding: 1.5rem 1rem;
  background: linear-gradient(135deg, #2c3e50, #34495e);
  color: white;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.mobile-user-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.mobile-user-info .user-avatar {
  width: 36px;
  height: 36px;
  font-size: 1rem;
}

.mobile-user-info .user-email {
  font-size: 0.875rem;
}

.mobile-menu-close {
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.mobile-menu-content {
  flex: 1;
  padding: 1rem 0;
  overflow-y: auto;
}

.mobile-section {
  margin-bottom: 1.5rem;
}

.mobile-section-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: uppercase;
  color: #6c757d;
  letter-spacing: 0.5px;
}

.mobile-section-items {
  list-style: none;
}

.mobile-nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1rem;
  color: #2c3e50;
  text-decoration: none;
  transition: all 0.2s ease;
}

.mobile-nav-item:hover {
  background: #f8f9fa;
}

.mobile-nav-item.active {
  background: rgba(239, 127, 71, 0.1);
  color: #ef7f47;
  border-right: 3px solid #ef7f47;
}

.mobile-nav-item i {
  font-size: 1.1rem;
  min-width: 20px;
}

.mobile-menu-footer {
  padding: 1rem;
  border-top: 1px solid #e9ecef;
}

.mobile-logout-btn {
  width: 100%;
  background: none;
  border: 1px solid #dc3545;
  color: #dc3545;
  padding: 0.75rem;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s ease;
}

.mobile-logout-btn:hover {
  background: #dc3545;
  color: white;
}

/* ===== RESPONSIVE DESIGN ===== */
@media (max-width: 1024px) {
  .sidebar {
    display: none;
  }

  .mobile-header {
    display: block;
  }

  .main-content {
    margin-left: 0;
    padding-top: 60px;
  }
}

@media (max-width: 480px) {
  .mobile-container {
    padding: 0 0.75rem;
  }

  .brand-text {
    font-size: 0.875rem;
  }

  .mobile-menu {
    width: 100%;
  }
}
</style>
