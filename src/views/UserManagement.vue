<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/lib/supabase'

const toast = useToast()

const loading = ref(false)
const showInviteDialog = ref(false)
const users = ref<any[]>([])

const inviteForm = ref({
  email: '',
  role: 'user' as 'admin' | 'user'
})

const roleOptions = ref([
  { label: 'Usuário', value: 'user' },
  { label: 'Administrador', value: 'admin' }
])

// Load existing users
const loadUsers = async () => {
  try {
    const { data, error } = await supabase.auth.admin.listUsers()

    if (error) throw error

    users.value = data.users.map(user => ({
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      last_sign_in_at: user.last_sign_in_at,
      email_confirmed_at: user.email_confirmed_at,
      role: user.user_metadata?.role || 'user',
      status: user.email_confirmed_at ? 'active' : 'pending'
    }))
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao carregar usuários: ' + error.message,
      life: 3000
    })
  }
}

// Invite new user
const inviteUser = async () => {
  if (!inviteForm.value.email) {
    toast.add({
      severity: 'warn',
      summary: 'Email obrigatório',
      detail: 'Por favor, digite o email do usuário',
      life: 3000
    })
    return
  }

  loading.value = true

  try {
    const { error } = await supabase.auth.admin.inviteUserByEmail(inviteForm.value.email, {
      data: {
        role: inviteForm.value.role
      },
      redirectTo: `${window.location.origin}/login`
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: 'Convite enviado',
      detail: 'Convite enviado com sucesso para ' + inviteForm.value.email,
      life: 3000
    })

    showInviteDialog.value = false
    inviteForm.value.email = ''
    inviteForm.value.role = 'user'

    // Reload users
    await loadUsers()

  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: error.message || 'Erro ao enviar convite',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

// Delete user
const deleteUser = async (userId: string, email: string) => {
  try {
    const { error } = await supabase.auth.admin.deleteUser(userId)

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: 'Usuário removido',
      detail: `Usuário ${email} removido com sucesso`,
      life: 3000
    })

    await loadUsers()
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao remover usuário: ' + error.message,
      life: 3000
    })
  }
}

const confirmDelete = (userId: string, email: string) => {
  if (confirm(`Tem certeza que deseja remover o usuário ${email}?`)) {
    deleteUser(userId, email)
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getStatusSeverity = (status: string) => {
  return status === 'active' ? 'success' : 'warning'
}

const getStatusLabel = (status: string) => {
  return status === 'active' ? 'Ativo' : 'Pendente'
}

const getRoleLabel = (role: string) => {
  return role === 'admin' ? 'Administrador' : 'Usuário'
}

const getRoleSeverity = (role: string) => {
  return role === 'admin' ? 'info' : 'secondary'
}

onMounted(() => {
  loadUsers()
})
</script>

<template>
  <div class="user-management">
    <div class="container">
      <div class="header-section">
        <h2>👥 Gerenciamento de Usuários</h2>
        <div class="header-actions">
          <Button
            label="Voltar ao Dashboard"
            icon="pi pi-arrow-left"
            class="p-button-outlined"
            @click="$router.push('/')"
          />
          <Button
            label="Convidar Usuário"
            icon="pi pi-user-plus"
            @click="showInviteDialog = true"
          />
        </div>
      </div>

      <!-- Users Table -->
      <div class="table-section">
        <DataTable
          :value="users"
          :paginator="true"
          :rows="20"
          :rowsPerPageOptions="[10, 20, 50]"
          sortField="created_at"
          :sortOrder="-1"
          class="p-datatable-sm"
          stripedRows
          responsiveLayout="scroll"
        >
          <Column field="email" header="Email" sortable>
            <template #body="{ data }">
              <div class="user-info">
                <strong>{{ data.email }}</strong>
                <small>ID: {{ data.id.substring(0, 8) }}...</small>
              </div>
            </template>
          </Column>

          <Column field="role" header="Papel" sortable style="width: 120px">
            <template #body="{ data }">
              <Tag
                :value="getRoleLabel(data.role)"
                :severity="getRoleSeverity(data.role)"
              />
            </template>
          </Column>

          <Column field="status" header="Status" sortable style="width: 120px">
            <template #body="{ data }">
              <Tag
                :value="getStatusLabel(data.status)"
                :severity="getStatusSeverity(data.status)"
              />
            </template>
          </Column>

          <Column field="created_at" header="Criado em" sortable style="width: 150px">
            <template #body="{ data }">
              {{ formatDate(data.created_at) }}
            </template>
          </Column>

          <Column field="last_sign_in_at" header="Último login" sortable style="width: 150px">
            <template #body="{ data }">
              {{ data.last_sign_in_at ? formatDate(data.last_sign_in_at) : 'Nunca' }}
            </template>
          </Column>

          <Column header="Ações" style="width: 100px">
            <template #body="{ data }">
              <Button
                icon="pi pi-trash"
                class="p-button-outlined p-button-danger p-button-sm"
                @click="confirmDelete(data.id, data.email)"
                v-tooltip.top="'Remover usuário'"
              />
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Invite User Dialog -->
    <Dialog
      v-model:visible="showInviteDialog"
      header="Convidar Usuário"
      :modal="true"
      style="width: 450px"
    >
      <div class="invite-form">
        <div class="field">
          <label for="email">Email</label>
          <InputText
            id="email"
            v-model="inviteForm.email"
            type="email"
            placeholder="Digite o email do usuário"
            style="width: 100%"
            :class="{ 'p-invalid': !inviteForm.email && inviteForm.email !== '' }"
          />
        </div>

        <div class="field">
          <label for="role">Papel</label>
          <Dropdown
            id="role"
            v-model="inviteForm.role"
            :options="roleOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Selecione o papel"
            style="width: 100%"
          />
        </div>

        <div class="info-card">
          <div class="info-header">
            <i class="pi pi-info-circle"></i>
            <span>Informações do convite</span>
          </div>
          <ul>
            <li>O usuário receberá um email de convite</li>
            <li>Ele poderá definir sua própria senha</li>
            <li>O convite expira em 24 horas</li>
            <li v-if="inviteForm.role === 'admin'">⚠️ Administradores têm acesso total ao sistema</li>
          </ul>
        </div>
      </div>

      <template #footer>
        <Button
          label="Cancelar"
          icon="pi pi-times"
          class="p-button-text"
          @click="showInviteDialog = false"
        />
        <Button
          label="Enviar Convite"
          icon="pi pi-send"
          class="p-button-primary"
          :loading="loading"
          @click="inviteUser"
        />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<style scoped>
.user-management {
  min-height: 100vh;
  background: #f8f9fa;
}

.container {
  width: 100%;
  max-width: none;
  margin: 0;
  padding: 1rem;
  overflow-x: hidden;
}

.header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding: 1rem 0;
}

.header-section h2 {
  margin: 0;
  color: #2c3e50;
  font-size: 2rem;
}

.header-actions {
  display: flex;
  gap: 1rem;
}

.table-section {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.user-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.user-info small {
  color: #6c757d;
  font-size: 0.8rem;
}

.invite-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  padding: 1rem 0;
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

.info-card {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 0.5rem;
  padding: 1rem;
  margin-top: 0.5rem;
}

.info-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 0.75rem;
}

.info-header i {
  color: #3b82f6;
}

.info-card ul {
  margin: 0;
  padding-left: 1.25rem;
  color: #6c757d;
  font-size: 0.9rem;
}

.info-card li {
  margin-bottom: 0.5rem;
}

/* Mobile responsiveness */
@media (max-width: 768px) {
  .header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .header-actions {
    width: 100%;
    justify-content: flex-start;
  }

  .container {
    padding: 0.5rem;
  }
}
</style>