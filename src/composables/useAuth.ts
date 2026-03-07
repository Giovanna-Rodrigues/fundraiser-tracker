import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'

export type UserRole = 'admin' | 'user' | 'treasurer' | 'secretary'

interface CurrentUser {
  email: string | undefined
  id: string
  role: UserRole
}

const currentUser = ref<CurrentUser | null>(null)

export const useAuth = () => {
  const router = useRouter()
  const route = useRoute()

  const isAuthenticated = computed(() => !!currentUser.value)
  const userRole = computed(() => currentUser.value?.role || 'user')
  const isAdmin = computed(() => currentUser.value?.role === 'admin')
  const isTreasurer = computed(() => currentUser.value?.role === 'treasurer' || currentUser.value?.role === 'admin')
  const isSecretary = computed(() => currentUser.value?.role === 'secretary' || currentUser.value?.role === 'admin')

  const hasRole = (roles: UserRole | UserRole[]): boolean => {
    if (!currentUser.value) return false
    const roleArray = Array.isArray(roles) ? roles : [roles]
    return roleArray.includes(currentUser.value.role)
  }

  const initializeAuth = async () => {
    // Gets the current session
    const { data: { session } } = await supabase.auth.getSession()

    // Verify if there's a user in the session
    if (session?.user) {
      // Sets current user and saves to localStorage
      currentUser.value = {
        email: session.user.email,
        id: session.user.id,
        role: (session.user.user_metadata?.role as UserRole) || 'user'
      }
      localStorage.setItem('user', JSON.stringify(currentUser.value))
    } else {
      // Try to get user from localStorage
      const savedUser = localStorage.getItem('user')
      if (savedUser) {
        currentUser.value = JSON.parse(savedUser)
      }
    }

    // Use setTimeout to ensure router has processed the URL
    setTimeout(() => {
      // Redirect to login if not authenticated (except for public pages)
      const publicPages = ['/login', '/reset-password']
      const currentPath = router.currentRoute.value.path
      const currentQuery = router.currentRoute.value.query
      const hasInvitationToken = currentQuery.token_hash && (currentQuery.type === 'invite' || currentQuery.type === 'recovery')

      console.log('Auth check:', {
        path: currentPath,
        query: currentQuery,
        hasToken: hasInvitationToken,
        isAuthenticated: !!currentUser.value
      })

      if (!currentUser.value && !publicPages.includes(currentPath) && !hasInvitationToken) {
        console.log('Redirecting to login')
        router.push('/login')
      }
    }, 100)
  }

  const setupAuthListener = () => {
    supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        currentUser.value = null
        localStorage.removeItem('user')
        router.push('/login')
      } else if (session?.user) {
        currentUser.value = {
          email: session.user.email,
          id: session.user.id,
          role: (session.user.user_metadata?.role as UserRole) || 'user'
        }
        localStorage.setItem('user', JSON.stringify(currentUser.value))
      }
    })
  }

  const logout = async () => {
    await supabase.auth.signOut()
    localStorage.removeItem('user')
    currentUser.value = null
    router.push('/login')
  }

  return {
    currentUser,
    isAuthenticated,
    userRole,
    isAdmin,
    isTreasurer,
    isSecretary,
    hasRole,
    initializeAuth,
    setupAuthListener,
    logout
  }
}