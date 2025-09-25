
<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const toast = useToast()

const submitted = ref(false)
const loading = ref(false)
const showForgotPassword = ref(false)

const loginForm = ref({
  email: '',
  password: '',
  rememberMe: false
})

const resetPasswordForm = ref({
  email: ''
})

const handleLogin = async (event?: Event) => {
  if (event) {
    event.preventDefault()
  }
  submitted.value = true

  if (!loginForm.value.email || !loginForm.value.password) {
    return
  }

  loading.value = true

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: loginForm.value.email,
      password: loginForm.value.password
    })

    if (error) throw error

    if (data.user) {
      localStorage.setItem('user', JSON.stringify({
        email: data.user.email,
        id: data.user.id,
        loginTime: new Date().toISOString()
      }))

      toast.add({
        severity: 'success',
        summary: 'Login realizado',
        detail: `Bem-vindo!`,
        life: 3000
      })

      router.push('/')
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro de login',
      detail: error.message || 'Credenciais inválidas',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}


const handlePasswordReset = async () => {
  if (!resetPasswordForm.value.email) {
    toast.add({
      severity: 'warn',
      summary: 'Email obrigatório',
      detail: 'Por favor, digite seu email para recuperar a senha',
      life: 3000
    })
    return
  }

  loading.value = true

  try {
    const { error } = await supabase.auth.resetPasswordForEmail(resetPasswordForm.value.email, {
      redirectTo: `${window.location.origin}/reset-password`
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: 'Email enviado',
      detail: 'Verifique seu email para instruções de redefinição de senha',
      life: 5000
    })

    showForgotPassword.value = false
    resetPasswordForm.value.email = ''
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: error.message || 'Erro ao enviar email de recuperação',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-container">
      <div class="login-card">
        <!-- Logo/Header -->
        <div class="login-header">
          <div class="logo">
            <i class="pi pi-users"></i>
          </div>
          <h1>Campanhas Genesis</h1>
          <p>Sistema de Controle de Vendas</p>
        </div>

        <!-- Login Form -->
        <div class="login-form">
          <div class="field">
            <label for="email">Email</label>
            <div class="p-inputgroup">
              <span class="p-inputgroup-addon">
                <i class="pi pi-envelope"></i>
              </span>
              <InputText
                id="email"
                type="email"
                v-model="loginForm.email"
                placeholder="Digite seu email"
                :class="{ 'p-invalid': submitted && !loginForm.email }"
                required
              />
            </div>
            <small v-if="submitted && !loginForm.email" class="p-error">
              Email é obrigatório.
            </small>
          </div>

          <div class="field">
            <label for="password">Senha</label>
            <div class="p-inputgroup">
              <span class="p-inputgroup-addon">
                <i class="pi pi-lock"></i>
              </span>
              <InputText
                id="password"
                type="password"
                v-model="loginForm.password"
                placeholder="Digite sua senha"
                :class="{ 'p-invalid': submitted && !loginForm.password }"
                required
              />
            </div>
            <small v-if="submitted && !loginForm.password" class="p-error">
              Senha é obrigatória.
            </small>
          </div>

          <div class="field checkbox-field">
            <Checkbox
              id="remember"
              v-model="loginForm.rememberMe"
              binary
            />
            <label for="remember">Lembrar de mim</label>
          </div>

          <div class="login-actions">
            <Button
              label="Entrar"
              class="p-button-primary login-btn"
              :loading="loading"
              icon="pi pi-sign-in"
              @click="handleLogin()"
            />
          </div>
        </div>

        <!-- Additional Options -->
        <div class="login-footer">
          <Divider />
          <div class="footer-links">
            <Button
              label="Esqueci minha senha"
              class="p-button-link"
              @click="showForgotPassword = true"
            />
          </div>
        </div>
      </div>

      <!-- Background decoration -->
      <div class="background-decoration">
        <div class="circle circle-1"></div>
        <div class="circle circle-2"></div>
        <div class="circle circle-3"></div>
      </div>
    </div>

    <!-- Forgot Password Dialog -->
    <Dialog
      v-model:visible="showForgotPassword"
      header="Recuperar Senha"
      :modal="true"
      style="width: 400px"
    >
      <div class="dialog-content">
        <p>Digite seu email para receber instruções de redefinição de senha.</p>
        <div class="field">
          <label for="resetEmail">Email</label>
          <InputText
            id="resetEmail"
            v-model="resetPasswordForm.email"
            type="email"
            placeholder="Digite seu email"
            style="width: 100%"
            :class="{ 'p-invalid': !resetPasswordForm.email && resetPasswordForm.email !== '' }"
          />
        </div>
      </div>
      <template #footer>
        <Button
          label="Cancelar"
          icon="pi pi-times"
          class="p-button-text"
          @click="showForgotPassword = false"
        />
        <Button
          label="Enviar"
          icon="pi pi-send"
          class="p-button-primary"
          :loading="loading"
          @click="handlePasswordReset"
        />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<style scoped>
.login-page {
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

.login-container {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 380px;
  padding: 1rem;
}

.login-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 1rem;
  padding: 1.5rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.login-header {
  text-align: center;
  margin-bottom: 1.5rem;
}

.logo {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 60px;
  height: 60px;
  background: linear-gradient(135deg, var(--primary-color, #ef7f47), #f7a169);
  border-radius: 50%;
  margin-bottom: 0.75rem;
  box-shadow: 0 8px 20px rgba(239, 127, 71, 0.3);
}

.logo i {
  font-size: 2rem;
  color: white;
}

.login-header h1 {
  margin: 0 0 0.25rem;
  color: #2c3e50;
  font-size: 1.5rem;
  font-weight: 700;
}

.login-header p {
  margin: 0;
  color: #6c757d;
  font-size: 0.9rem;
}

.login-form {
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

.checkbox-field {
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
}

.checkbox-field label {
  margin: 0;
  cursor: pointer;
}

.login-actions {
  margin-top: 0.75rem;
}

.login-btn {
  width: 100%;
  padding: 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 0.5rem;
}

.login-footer {
  margin-top: 1.25rem;
}

.footer-links {
  text-align: center;
  margin-top: 0.75rem;
}

.p-inputgroup {
  width: 100%;
  display: flex;
}

.p-inputgroup-addon {
  min-width: 2.5rem;
  flex-shrink: 0;
}

.p-inputgroup-addon i {
  margin-right: 0.25rem;
}

.p-inputgroup .p-inputtext {
  flex: 1;
}

.background-decoration {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
}

.circle {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  animation: float 6s ease-in-out infinite;
}

.circle-1 {
  width: 200px;
  height: 200px;
  top: 10%;
  left: -5%;
  animation-delay: 0s;
}

.circle-2 {
  width: 150px;
  height: 150px;
  bottom: 15%;
  right: -3%;
  animation-delay: 2s;
}

.circle-3 {
  width: 100px;
  height: 100px;
  top: 50%;
  right: 10%;
  animation-delay: 4s;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-20px);
  }
}

.dialog-content {
  padding: 1rem 0;
}

.dialog-content p {
  margin-bottom: 1rem;
  color: #6c757d;
  line-height: 1.5;
}

.p-invalid {
  border-color: #e24c4c;
}

.p-error {
  color: #e24c4c;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

/* Mobile responsiveness */
@media (max-width: 480px) {
  .login-container {
    padding: 1rem;
    max-width: 100%;
  }

  .login-card {
    padding: 2rem 1.5rem;
  }

  .login-header h1 {
    font-size: 1.5rem;
  }

  .logo {
    width: 60px;
    height: 60px;
  }

  .logo i {
    font-size: 2rem;
  }
}
</style>