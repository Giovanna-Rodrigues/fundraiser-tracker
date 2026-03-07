import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/Login.vue'),
    },
    {
      path: '/reset-password',
      name: 'reset-password',
      component: () => import('../views/ResetPassword.vue'),
    },
    {
      path: '/',
      name: 'dashboard',
      component: () => import('../views/Dashboard.vue'),
    },
    {
      path: '/orders',
      name: 'orders',
      component: () => import('../views/OrderEntry.vue'),
    },
    {
      path: '/kitchen',
      name: 'kitchen',
      component: () => import('../views/Kitchen.vue'),
    },
    {
      path: '/pathfinders',
      name: 'pathfinders',
      component: () => import('../views/PathfinderManagement.vue'),
    },
    {
      path: '/leaderboard',
      name: 'leaderboard',
      component: () => import('../views/Leaderboard.vue'),
    },
    {
      path: '/sales-list',
      name: 'sales-list',
      component: () => import('../views/SalesList.vue'),
    },
    {
      path: '/cost-calculation',
      name: 'cost-calculation',
      component: () => import('../views/CostCalculation.vue'),
    },
    {
      path: '/products',
      name: 'products',
      component: () => import('../views/ProductsManagement.vue'),
    },
    {
      path: '/campaigns',
      name: 'campaigns',
      component: () => import('../views/CampaignManagement.vue'),
    },
    {
      path: '/users',
      name: 'users',
      component: () => import('../views/UserManagement.vue'),
    },
    {
      path: '/financial',
      name: 'financial',
      component: () => import('../views/FinancialTracking.vue'),
    },
    {
      path: '/documents',
      name: 'documents',
      component: () => import('../views/DocumentTracking.vue'),
    },
    // Legacy routes redirect
    {
      path: '/sales',
      redirect: '/orders'
    },
  ],
})

// Navigation guard — redirect to login if not authenticated
router.beforeEach((to, from, next) => {
  const publicRoutes = ['/login', '/reset-password']
  if (publicRoutes.includes(to.path)) {
    next()
    return
  }

  const { currentUser } = useAuth()
  if (!currentUser.value) {
    next('/login')
  } else {
    next()
  }
})

export default router
