<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { menuSections } from '@/config/navigation'

interface Props {
  collapsed: boolean
}

defineProps<Props>()
defineEmits<{
  toggle: []
}>()

const route = useRoute()
const { currentUser, logout } = useAuth()
</script>

<template>
  <aside class="sidebar" :class="{ collapsed }">
    <!-- Sidebar Header -->
    <div class="sidebar-header">
      <div class="brand" v-if="!collapsed">
        <img src="/logo.jpeg" alt="Logo do Clube" class="brand-logo" />
        <div class="brand-info">
          <span class="brand-title">Campanha</span>
          <span class="brand-subtitle">Desbravadores</span>
        </div>
      </div>
      <button class="sidebar-toggle" @click="$emit('toggle')">
        <i class="pi" :class="collapsed ? 'pi-angle-right' : 'pi-angle-left'"></i>
      </button>
    </div>

    <!-- Navigation Menu -->
    <nav class="sidebar-nav">
      <div v-for="section in menuSections" :key="section.title" class="nav-section">
        <div class="section-header" v-if="!collapsed">
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
              :title="collapsed ? item.label : ''"
            >
              <i :class="item.icon"></i>
              <span v-if="!collapsed">{{ item.label }}</span>
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
        <div class="user-details" v-if="!collapsed">
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
</template>

<style scoped>
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

/* ===== RESPONSIVE DESIGN ===== */
@media (max-width: 1024px) {
  .sidebar {
    display: none;
  }
}
</style>