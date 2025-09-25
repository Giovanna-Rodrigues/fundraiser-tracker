<script setup lang="ts">
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { menuSections } from '@/config/navigation'

const route = useRoute()
const { currentUser, logout } = useAuth()
const menuVisible = ref(false)

const toggleMenu = () => {
  menuVisible.value = !menuVisible.value
}
</script>

<template>
  <header class="mobile-header">
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
</template>

<style scoped>
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
  border-radius: 50%;
  object-fit: cover;
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
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
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
  .mobile-header {
    display: block;
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