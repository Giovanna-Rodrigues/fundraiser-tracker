
<script setup lang="ts">
import { ref } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { Campaign } from '@/stores/fundraiser'

const fundraiserStore = useFundraiserStore()
const toast = useToast()

const showCreateDialog = ref(false)
const showDeleteDialog = ref(false)
const submitted = ref(false)
const editingCampaign = ref<Campaign | null>(null)
const campaignToDelete = ref<Campaign | null>(null)

const campaignForm = ref({
  Name: '',
  Description: '',
  StartDate: null as Date | null,
  EndDate: null as Date | null,
  Status: 'planned' as 'planned' | 'active' | 'completed',
  Goal: null as number | null
})

const statusOptions = ref([
  { label: 'Planejada', value: 'planned' },
  { label: 'Ativa', value: 'active' },
  { label: 'Concluída', value: 'completed' }
])

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('pt-BR')
}

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value || 0)
}

const getStatusLabel = (status: string) => {
  const labels = {
    planned: 'Planejada',
    active: 'Ativa',
    completed: 'Concluída'
  }
  return labels[status as keyof typeof labels] || status
}

const getStatusSeverity = (status: string) => {
  const severities = {
    planned: 'info',
    active: 'success',
    completed: 'secondary'
  }
  return severities[status as keyof typeof severities] || 'info'
}

const editCampaign = (campaign: Campaign) => {
  editingCampaign.value = campaign
  campaignForm.value = {
    Name: campaign.Name,
    Description: campaign.Description || '',
    StartDate: new Date(campaign.StartDate),
    EndDate: new Date(campaign.EndDate),
    Status: campaign.Status,
    Goal: campaign.Goal || null
  }
  showCreateDialog.value = true
}

const activateCampaign = async (campaign: Campaign) => {
  try {
    await fundraiserStore.updateCampaign(campaign.PK, { Status: 'active' })
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Campanha ativada com sucesso!',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao ativar campanha',
      life: 3000
    })
  }
}

const completeCampaign = async (campaign: Campaign) => {
  try {
    await fundraiserStore.updateCampaign(campaign.PK, { Status: 'completed' })
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Campanha concluída com sucesso!',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao concluir campanha',
      life: 3000
    })
  }
}

const confirmDelete = (campaign: Campaign) => {
  campaignToDelete.value = campaign
  showDeleteDialog.value = true
}

const deleteCampaign = async () => {
  if (!campaignToDelete.value) return

  try {
    await fundraiserStore.deleteCampaign(campaignToDelete.value.PK)
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Campanha excluída com sucesso!',
      life: 3000
    })
    showDeleteDialog.value = false
    campaignToDelete.value = null
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao excluir campanha',
      life: 3000
    })
  }
}

const saveCampaign = async () => {
  submitted.value = true

  if (!campaignForm.value.Name || !campaignForm.value.StartDate || !campaignForm.value.EndDate || !campaignForm.value.Status) {
    return
  }

  try {
    const campaignData = {
      Name: campaignForm.value.Name,
      Description: campaignForm.value.Description || undefined,
      StartDate: campaignForm.value.StartDate.toISOString().split('T')[0],
      EndDate: campaignForm.value.EndDate.toISOString().split('T')[0],
      Status: campaignForm.value.Status,
      Goal: campaignForm.value.Goal || undefined
    }

    if (editingCampaign.value) {
      await fundraiserStore.updateCampaign(editingCampaign.value.PK, campaignData)
      toast.add({
        severity: 'success',
        summary: 'Sucesso',
        detail: 'Campanha atualizada com sucesso!',
        life: 3000
      })
    } else {
      await fundraiserStore.addCampaign(campaignData)
      toast.add({
        severity: 'success',
        summary: 'Sucesso',
        detail: 'Campanha criada com sucesso!',
        life: 3000
      })
    }

    closeDialog()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao salvar campanha',
      life: 3000
    })
  }
}

const closeDialog = () => {
  showCreateDialog.value = false
  editingCampaign.value = null
  campaignForm.value = {
    Name: '',
    Description: '',
    StartDate: null,
    EndDate: null,
    Status: 'planned',
    Goal: null
  }
  submitted.value = false
}
</script>

<template>
  <div class="campaign-management">
    <div class="container">
      <div class="header-section">
        <h2>🎯 Gerenciar Campanhas</h2>
        <Button
          label="Nova Campanha"
          icon="pi pi-plus"
          class="p-button-success"
          @click="showCreateDialog = true"
        />
      </div>

      <DataTable :value="fundraiserStore.campaigns" class="p-datatable-sm" :paginator="true" :rows="10">
        <Column field="Name" header="Nome" sortable></Column>
        <Column field="StartDate" header="Data Início" sortable>
          <template #body="{ data }">
            {{ formatDate(data.StartDate) }}
          </template>
        </Column>
        <Column field="EndDate" header="Data Fim" sortable>
          <template #body="{ data }">
            {{ formatDate(data.EndDate) }}
          </template>
        </Column>
        <Column field="Status" header="Status" sortable>
          <template #body="{ data }">
            <Tag
              :value="getStatusLabel(data.Status)"
              :severity="getStatusSeverity(data.Status)"
            />
          </template>
        </Column>
        <Column field="Goal" header="Meta">
          <template #body="{ data }">
            {{ data.Goal ? formatCurrency(data.Goal) : '-' }}
          </template>
        </Column>
        <Column header="Ações" style="width: 200px">
          <template #body="{ data }">
            <Button
              icon="pi pi-pencil"
              class="p-button-text p-button-sm"
              @click="editCampaign(data)"
              v-tooltip.top="'Editar'"
            />
            <Button
              v-if="data.Status === 'planned'"
              icon="pi pi-play"
              class="p-button-text p-button-sm p-button-success"
              @click="activateCampaign(data)"
              v-tooltip.top="'Ativar'"
            />
            <Button
              v-if="data.Status === 'active'"
              icon="pi pi-check"
              class="p-button-text p-button-sm p-button-warning"
              @click="completeCampaign(data)"
              v-tooltip.top="'Concluir'"
            />
            <Button
              icon="pi pi-trash"
              class="p-button-text p-button-sm p-button-danger"
              @click="confirmDelete(data)"
              v-tooltip.top="'Excluir'"
            />
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- Create/Edit Dialog -->
    <Dialog
      v-model:visible="showCreateDialog"
      :header="editingCampaign ? 'Editar Campanha' : 'Nova Campanha'"
      :modal="true"
      style="width: 500px"
    >
      <div class="dialog-content">
        <div class="field">
          <label for="name">Nome *</label>
          <InputText
            id="name"
            v-model="campaignForm.Name"
            :class="{ 'p-invalid': submitted && !campaignForm.Name }"
            style="width: 100%"
          />
          <small v-if="submitted && !campaignForm.Name" class="p-error">
            Nome é obrigatório.
          </small>
        </div>

        <div class="field">
          <label for="description">Descrição</label>
          <Textarea
            id="description"
            v-model="campaignForm.Description"
            rows="3"
            style="width: 100%"
          />
        </div>

        <div class="field-row">
          <div class="field">
            <label for="startDate">Data Início *</label>
            <Calendar
              id="startDate"
              v-model="campaignForm.StartDate"
              dateFormat="dd/mm/yy"
              :class="{ 'p-invalid': submitted && !campaignForm.StartDate }"
              style="width: 100%"
            />
            <small v-if="submitted && !campaignForm.StartDate" class="p-error">
              Data início é obrigatória.
            </small>
          </div>

          <div class="field">
            <label for="endDate">Data Fim *</label>
            <Calendar
              id="endDate"
              v-model="campaignForm.EndDate"
              dateFormat="dd/mm/yy"
              :class="{ 'p-invalid': submitted && !campaignForm.EndDate }"
              style="width: 100%"
            />
            <small v-if="submitted && !campaignForm.EndDate" class="p-error">
              Data fim é obrigatória.
            </small>
          </div>
        </div>

        <div class="field">
          <label for="goal">Meta (R$)</label>
          <InputNumber
            id="goal"
            v-model="campaignForm.Goal"
            mode="currency"
            currency="BRL"
            locale="pt-BR"
            style="width: 100%"
          />
        </div>

        <div class="field">
          <label for="status">Status *</label>
          <Dropdown
            id="status"
            v-model="campaignForm.Status"
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            :class="{ 'p-invalid': submitted && !campaignForm.Status }"
            style="width: 100%"
          />
        </div>
      </div>

      <template #footer>
        <Button
          label="Cancelar"
          icon="pi pi-times"
          class="p-button-text"
          @click="closeDialog"
        />
        <Button
          :label="editingCampaign ? 'Atualizar' : 'Criar'"
          icon="pi pi-check"
          @click="saveCampaign"
        />
      </template>
    </Dialog>

    <!-- Delete Confirmation Dialog -->
    <Dialog v-model:visible="showDeleteDialog" header="Confirmar Exclusão" :modal="true" style="width: 350px">
      <div class="confirmation-content">
        <i class="pi pi-exclamation-triangle" style="font-size: 2rem; color: var(--red-500)"></i>
        <span>Tem certeza que deseja excluir esta campanha?</span>
      </div>
      <template #footer>
        <Button label="Não" icon="pi pi-times" class="p-button-text" @click="showDeleteDialog = false" />
        <Button label="Sim" icon="pi pi-check" class="p-button-danger" @click="deleteCampaign" />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<style scoped>
.campaign-management {
  min-height: 100vh;
  background: #f8f9fa;
  padding: 2rem;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
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
  font-size: 2rem;
}

.dialog-content {
  padding: 1rem 0;
}

.field {
  margin-bottom: 1.5rem;
}

.field label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
}

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.p-invalid {
  border-color: #e24c4c;
}

.p-error {
  color: #e24c4c;
  font-size: 0.875rem;
  margin-top: 0.25rem;
  display: block;
}

.confirmation-content {
  display: flex;
  align-items: center;
  gap: 1rem;
}

@media (max-width: 768px) {
  .campaign-management {
    padding: 1rem;
  }

  .header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .field-row {
    grid-template-columns: 1fr;
  }
}
</style>