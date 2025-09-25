<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const loading = ref(false)
const isValidSession = ref(false)

const resetForm = ref({
  password: '',
  confirmPassword: ''
})

onMounted(async () => {
  // Check if we have token_hash in URL parameters
  const tokenHash = route.query.token_hash as string
  const type = route.query.type as string
  const accessToken = route.query.access_token as string
  const refreshToken = route.query.refresh_token as string

  console.log('Reset password page loaded with:', { tokenHash, type, accessToken, refreshToken })

  if (tokenHash && (type === 'recovery' || type === 'invite')) {
    try {
      // Verify the session using token hash from URL
      const { data, error } = await supabase.auth.verifyOtp({
        token_hash: tokenHash,
        type: type as 'recovery' | 'invite'
      })

      if (error) {
        console.error('Error verifying session:', error)
        throw error
      }

      if (data.session) {
        isValidSession.value = true
        toast.add({
          severity: 'success',
          summary: 'Link válido',
          detail: type === 'invite' ? 'Bem-vindo! Defina sua senha abaixo.' : 'Defina sua nova senha abaixo.',
          life: 3000
        })
      } else {
        throw new Error('No session established')
      }
    } catch (error: any) {
      console.error('Session verification failed:', error)
      toast.add({
        severity: 'error',
        summary: 'Link inválido',
        detail: 'Este link de recuperação é inválido ou expirou. Solicite um novo link.',
        life: 5000
      })
      setTimeout(() => router.push('/login'), 3000)
    }
  } else if (accessToken && refreshToken) {
    // Handle direct token authentication (alternative flow)
    try {
      const { data, error } = await supabase.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken
      })

      if (error) throw error

      if (data.session) {
        isValidSession.value = true
        toast.add({
          severity: 'success',
          summary: 'Sessão estabelecida',
          detail: 'Defina sua nova senha abaixo.',
          life: 3000
        })
      } else {
        throw new Error('Failed to establish session')
      }
    } catch (error: any) {
      console.error('Session setup failed:', error)
      toast.add({
        severity: 'error',
        summary: 'Link inválido',
        detail: 'Este link de recuperação é inválido ou expirou. Solicite um novo link.',
        life: 5000
      })
      setTimeout(() => router.push('/login'), 3000)
    }
  } else {
    console.log('No valid token found')
    toast.add({
      severity: 'info',
      summary: 'Acesso direto',
      detail: 'Esta página só pode ser acessada através de um link de email válido',
      life: 5000
    })
    setTimeout(() => router.push('/login'), 3000)
  }
})

const handleResetPassword = async () => {
  if (!resetForm.value.password || !resetForm.value.confirmPassword) {
    toast.add({
      severity: 'warn',
      summary: 'Campos obrigatórios',
      detail: 'Por favor, preencha todos os campos',
      life: 3000
    })
    return
  }

  if (resetForm.value.password !== resetForm.value.confirmPassword) {
    toast.add({
      severity: 'error',
      summary: 'Senhas não coincidem',
      detail: 'A confirmação da senha deve ser igual à nova senha',
      life: 3000
    })
    return
  }

  if (resetForm.value.password.length < 6) {
    toast.add({
      severity: 'error',
      summary: 'Senha muito curta',
      detail: 'A senha deve ter pelo menos 6 caracteres',
      life: 3000
    })
    return
  }

  loading.value = true

  try {
    const { error } = await supabase.auth.updateUser({
      password: resetForm.value.password
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: 'Senha alterada',
      detail: 'Sua senha foi alterada com sucesso!',
      life: 3000
    })

    // Redirect to login after success
    setTimeout(() => {
      router.push('/login')
    }, 2000)

  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: error.message || 'Erro ao alterar a senha',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="reset-password-page">
    <div class="reset-container">
      <div class="reset-card" v-if="isValidSession">
        <!-- Header -->
        <div class="reset-header">
          <div class="logo">
            <i class="pi pi-shield"></i>
          </div>
          <h1>Nova Senha</h1>
          <p>Digite sua nova senha abaixo</p>
        </div>

        <!-- Reset Form -->
        <div class="reset-form">
          <div class="field">
            <label for="newPassword">Nova Senha</label>
            <div class="p-inputgroup">
              <span class="p-inputgroup-addon">
                <i class="pi pi-lock"></i>
              </span>
              <InputText
                id="newPassword"
                type="password"
                v-model="resetForm.password"
                placeholder="Digite sua nova senha"
                required
              />
            </div>
          </div>

          <div class="field">
            <label for="confirmPassword">Confirmar Senha</label>
            <div class="p-inputgroup">
              <span class="p-inputgroup-addon">
                <i class="pi pi-lock"></i>
              </span>
              <InputText
                id="confirmPassword"
                type="password"
                v-model="resetForm.confirmPassword"
                placeholder="Confirme sua nova senha"
                required
              />
            </div>
          </div>

          <div class="reset-actions">
            <Button
              label="Alterar Senha"
              class="p-button-primary reset-btn"
              :loading="loading"
              icon="pi pi-check"
              @click="handleResetPassword"
            />
          </div>
        </div>

        <!-- Footer -->
        <div class="reset-footer">
          <Divider />
          <div class="footer-links">
            <Button
              label="Voltar ao Login"
              class="p-button-link"
              icon="pi pi-arrow-left"
              @click="$router.push('/login')"
            />
          </div>
        </div>
      </div>
    </div>

    <Toast />
  </div>
</template>

<style scoped>
.reset-password-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(rgba(102, 126, 234, 0.8), rgba(118, 75, 162, 0.8)), url('/genesis.jpeg');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  position: relative;
  overflow: hidden;
}

.reset-container {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 380px;
  padding: 1rem;
}

.reset-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 1rem;
  padding: 1.5rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.reset-header {
  text-align: center;
  margin-bottom: 1.5rem;
}

.logo {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 60px;
  height: 60px;
  background: linear-gradient(135deg, #ef7f47, #f7a169);
  border-radius: 50%;
  margin-bottom: 0.75rem;
  box-shadow: 0 8px 20px rgba(239, 127, 71, 0.3);
}

.logo i {
  font-size: 2rem;
  color: white;
}

.reset-header h1 {
  margin: 0 0 0.25rem;
  color: #2c3e50;
  font-size: 1.5rem;
  font-weight: 700;
}

.reset-header p {
  margin: 0;
  color: #6c757d;
  font-size: 0.9rem;
}

.reset-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.field label {
  font-weight: 600;
  color: #374151;
  font-size: 0.9rem;
}

.p-inputgroup {
  width: 100%;
  display: flex;
}

.p-inputgroup-addon {
  min-width: 2.5rem;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.p-inputgroup-addon i {
  margin: 0;
}

.p-inputgroup .p-inputtext {
  flex: 1;
  width: 0;
}

.reset-actions {
  margin-top: 0.75rem;
}

.reset-btn {
  width: 100%;
  padding: 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 0.5rem;
}

.reset-footer {
  margin-top: 1.25rem;
}

.footer-links {
  text-align: center;
  margin-top: 0.75rem;
}

/* Mobile responsiveness */
@media (max-width: 480px) {
  .reset-container {
    padding: 1rem;
    max-width: 100%;
  }

  .reset-card {
    padding: 1.25rem;
  }

  .reset-header h1 {
    font-size: 1.25rem;
  }

  .logo {
    width: 50px;
    height: 50px;
  }

  .logo i {
    font-size: 1.75rem;
  }
}
</style>