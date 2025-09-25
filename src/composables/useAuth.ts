import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'

const currentUser = ref<any>(null)

export const useAuth = () => {
  const router = useRouter()
  const route = useRoute()

  const isAuthenticated = computed(() => !!currentUser.value)

  const initializeAuth = async () => {
    // Gets the current session
    const { data: { session } } = await supabase.auth.getSession()

    // Verify if there's a user in the session
    if (session?.user) {
      // Sets current user and saves to localStorage
      currentUser.value = {
        email: session.user.email,
        id: session.user.id
      }
      localStorage.setItem('user', JSON.stringify(currentUser.value))
    } else {
      // Try to get user from localStorage
      const savedUser = localStorage.getItem('user')
      if (savedUser) {
        currentUser.value = JSON.parse(savedUser)
      }
    }

    // Redirect to login if not authenticated (except for public pages)
    const publicPages = ['/login', '/reset-password']
    const hasInvitationToken = route.query.token_hash && (route.query.type === 'invite' || route.query.type === 'recovery')

    if (!currentUser.value && !publicPages.includes(route.path) && !hasInvitationToken) {
      router.push('/login')
    }
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
          id: session.user.id
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
    initializeAuth,
    setupAuthListener,
    logout
  }
}