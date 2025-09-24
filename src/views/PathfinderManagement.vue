<template>
  <div class="pathfinder-management">
    <div class="header-section">
      <h2>Gerenciar Desbravadores</h2>
      <div class="header-actions">
        <Button
          label="Novo Desbravador"
          icon="pi pi-plus"
          @click="showAddDialog = true"
        />
        <Button
          label="Voltar ao Dashboard"
          icon="pi pi-arrow-left"
          class="p-button-outlined"
          @click="$router.push('/')"
        />
      </div>
    </div>

    <div class="content-card">
      <DataTable
        :value="pathfinders"
        :paginator="true"
        :rows="10"
        dataKey="PK"
        :loading="loading"
        class="p-datatable-gridlines"
      >
        <Column field="Name" header="Nome" sortable></Column>
        <Column field="CreatedAt" header="Cadastrado em" sortable>
          <template #body="{ data }">
            {{ formatDate(data.CreatedAt) }}
          </template>
        </Column>
        <Column header="Ações" style="width: 8rem">
          <template #body="{ data }">
            <div class="action-buttons">
              <Button
                icon="pi pi-pencil"
                class="p-button-rounded p-button-success p-button-sm"
                @click="editPathfinder(data)"
              />
              <Button
                icon="pi pi-trash"
                class="p-button-rounded p-button-danger p-button-sm"
                @click="confirmDeletePathfinder(data)"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- Add/Edit Dialog -->
    <Dialog
      v-model:visible="showAddDialog"
      :header="editingPathfinder ? 'Editar Desbravador' : 'Novo Desbravador'"
      :modal="true"
      style="width: 450px"
    >
      <div class="dialog-content">
        <div class="field">
          <label for="name">Nome *</label>
          <InputText
            id="name"
            v-model="pathfinderForm.Name"
            :class="{ 'p-invalid': submitted && !pathfinderForm.Name }"
            style="width: 100%"
          />
          <small v-if="submitted && !pathfinderForm.Name" class="p-error">Nome é obrigatório.</small>
        </div>

      </div>

      <template #footer>
        <Button label="Cancelar" icon="pi pi-times" class="p-button-text" @click="hideDialog" />
        <Button label="Salvar" icon="pi pi-check" @click="savePathfinder" />
      </template>
    </Dialog>

    <!-- Confirm Delete Dialog -->
    <Dialog
      v-model:visible="deletePathfinderDialog"
      style="width: 450px"
      header="Confirmar"
      :modal="true"
    >
      <div class="confirmation-content">
        <i class="pi pi-exclamation-triangle"></i>
        <span v-if="pathfinderToDelete">
          Tem certeza que deseja excluir <b>{{ pathfinderToDelete.Name }}</b>?
          <br />
          <small class="warning-text">Todas as vendas associadas também serão removidas.</small>
        </span>
      </div>
      <template #footer>
        <Button
          label="Não"
          icon="pi pi-times"
          class="p-button-text"
          @click="deletePathfinderDialog = false"
        />
        <Button
          label="Sim"
          icon="pi pi-check"
          class="p-button-text"
          @click="deletePathfinderConfirmed"
        />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { Pathfinder } from '@/stores/fundraiser'

// Store and utilities
const fundraiserStore = useFundraiserStore()
const toast = useToast()

// Component state
const loading = ref(false)
const showAddDialog = ref(false)
const deletePathfinderDialog = ref(false)
const submitted = ref(false)
const editingPathfinder = ref<Pathfinder | null>(null)
const pathfinderToDelete = ref<Pathfinder | null>(null)

// Form data
const pathfinderForm = ref({
  Name: ''
})

// Computed
const pathfinders = fundraiserStore.pathfinders

// Methods
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('pt-BR')
}

const hideDialog = () => {
  showAddDialog.value = false
  submitted.value = false
  editingPathfinder.value = null
  pathfinderForm.value = {
    Name: ''
  }
}

const editPathfinder = (pathfinder: Pathfinder) => {
  editingPathfinder.value = pathfinder
  pathfinderForm.value = {
    Name: pathfinder.Name
  }
  showAddDialog.value = true
}

const savePathfinder = async () => {
  submitted.value = true

  if (!pathfinderForm.value.Name?.trim()) {
    return
  }

  try {
    if (editingPathfinder.value) {
      await fundraiserStore.updatePathfinder(editingPathfinder.value.PK, {
        Name: pathfinderForm.value.Name.trim()
      })
      toast.add({
        severity: 'success',
        summary: 'Sucesso',
        detail: 'Desbravador atualizado com sucesso',
        life: 3000
      })
    } else {
      await fundraiserStore.addPathfinder({
        Name: pathfinderForm.value.Name.trim()
      })
      toast.add({
        severity: 'success',
        summary: 'Sucesso',
        detail: 'Desbravador adicionado com sucesso',
        life: 3000
      })
    }
    hideDialog()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao salvar desbravador',
      life: 3000
    })
  }
}

const confirmDeletePathfinder = (pathfinder: Pathfinder) => {
  pathfinderToDelete.value = pathfinder
  deletePathfinderDialog.value = true
}

const deletePathfinderConfirmed = async () => {
  if (!pathfinderToDelete.value) return

  try {
    await fundraiserStore.deletePathfinder(pathfinderToDelete.value.PK)
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Desbravador excluído com sucesso',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao excluir desbravador',
      life: 3000
    })
  }
  deletePathfinderDialog.value = false
  pathfinderToDelete.value = null
}

onMounted(async () => {
  // Data is already loaded from Supabase in the store
})
</script>

<style scoped>
.pathfinder-management {
  padding: 1rem;
  width: 100%;
}

.header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.header-section h2 {
  margin: 0;
  color: #2c3e50;
}

.header-actions {
  display: flex;
  gap: 1rem;
}

.content-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
}

.dialog-content {
  padding: 1rem 0;
}

.field {
  display: flex;
  flex-direction: column;
  margin-bottom: 1rem;
}

.field label {
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
}

.confirmation-content {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.confirmation-content i {
  font-size: 2rem;
  color: #f59e0b;
}

.warning-text {
  color: #dc2626;
}

.p-invalid {
  border-color: #e24c4c;
}

.p-error {
  color: #e24c4c;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

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
}
</style>