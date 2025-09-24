<template>
  <div class="login-page">
    <div class="login-container">
      <div class="login-card">
        <!-- Logo/Header -->
        <div class="login-header">
          <div class="logo">
            <i class="pi pi-users"></i>
          </div>
          <h1>Campanha Desbravadores</h1>
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
              :label="isSignUp ? 'Cadastrar' : 'Entrar'"
              class="p-button-primary login-btn"
              :loading="loading"
              :icon="isSignUp ? 'pi pi-user-plus' : 'pi pi-sign-in'"
              @click="isSignUp ? handleSignUp() : handleLogin()"
            />
          </div>
          <div class="signup-toggle">
            <Button
              :label="isSignUp ? 'Já tem conta? Entrar' : 'Criar nova conta'"
              class="p-button-link"
              @click="isSignUp = !isSignUp"
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
        <p>Entre em contato com o administrador do sistema para recuperar sua senha.</p>
        <div class="field">
          <label for="contactEmail">Email para contato</label>
          <InputText
            id="contactEmail"
            value="admin@desbravadores.com"
            readonly
            style="width: 100%"
          />
        </div>
      </div>
      <template #footer>
        <Button
          label="Fechar"
          icon="pi pi-times"
          class="p-button-text"
          @click="showForgotPassword = false"
        />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

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
const isSignUp = ref(false)

const loginForm = ref({
  email: '',
  password: '',
  rememberMe: false
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

const handleSignUp = async () => {
  submitted.value = true

  if (!loginForm.value.email || !loginForm.value.password) {
    return
  }

  loading.value = true

  try {
    const { data, error } = await supabase.auth.signUp({
      email: loginForm.value.email,
      password: loginForm.value.password
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: 'Conta criada',
      detail: 'Verifique seu email para confirmar',
      life: 5000
    })

    isSignUp.value = false
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro no cadastro',
      detail: error.message,
      life: 3000
    })
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  position: relative;
  overflow: hidden;
}

.login-container {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 400px;
  padding: 2rem;
}

.login-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 1rem;
  padding: 2.5rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.logo {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, var(--primary-color, #ef7f47), #f7a169);
  border-radius: 50%;
  margin-bottom: 1rem;
  box-shadow: 0 8px 20px rgba(239, 127, 71, 0.3);
}

.logo i {
  font-size: 2.5rem;
  color: white;
}

.login-header h1 {
  margin: 0 0 0.5rem;
  color: #2c3e50;
  font-size: 1.75rem;
  font-weight: 700;
}

.login-header p {
  margin: 0;
  color: #6c757d;
  font-size: 1rem;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
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
  margin-top: 1rem;
}

.login-btn {
  width: 100%;
  padding: 0.875rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 0.5rem;
}

.login-footer {
  margin-top: 2rem;
}

.footer-links {
  text-align: center;
  margin-top: 1rem;
}

.signup-toggle {
  text-align: center;
  margin-top: 1rem;
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