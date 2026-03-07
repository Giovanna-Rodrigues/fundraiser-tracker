<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useFundraiserStore } from '@/stores/fundraiser'
import type { Pathfinder, DocumentCompletionStatus, DocumentStatusMap } from '@/stores/fundraiser'

const toast = useToast()
const store = useFundraiserStore()

// State
const loading = ref(false)
const showBulkUpdateDialog = ref(false)
const expandedRows = ref<any>([])

// Filters
const globalFilter = ref('')
const typeFilter = ref<string | null>(null)
const completionFilter = ref<string | null>(null)
const yearFilter = ref<number | null>(null)

// Bulk Update Form
const bulkUpdateForm = ref({
  PathfinderIds: [] as string[],
  DocumentKey: '' as keyof DocumentStatusMap,
  Status: 'received' as 'received' | 'missing',
  Notes: ''
})

// Document Options
const documentOptions = ref<{ label: string; value: keyof DocumentStatusMap; requiredFor: string[] }[]>([
  { label: 'RG + CPF', value: 'id_cpf', requiredFor: ['all'] },
  { label: 'Cartão SUS', value: 'sus_card', requiredFor: ['all'] },
  { label: 'Comprovante de Residência', value: 'proof_residence', requiredFor: ['all'] },
  { label: 'RG + CPF dos Pais', value: 'parent_id_cpf', requiredFor: ['desbravador'] },
  { label: 'Cartão de Vacinação', value: 'vaccination_card', requiredFor: ['desbravador'] },
  { label: 'Antecedentes Criminais', value: 'criminal_background', requiredFor: ['staff', 'directors'] },
  { label: 'Cartão de Plano de Saúde', value: 'health_insurance', requiredFor: ['optional'] }
])

const statusOptions = ref([
  { label: 'Recebido', value: 'received' },
  { label: 'Faltando', value: 'missing' }
])

const typeFilterOptions = ref([
  { label: 'Todos', value: null },
  { label: 'Desbravador', value: 'desbravador' },
  { label: 'Staff', value: 'staff' },
  { label: 'Diretoria', value: 'directors' }
])

const completionFilterOptions = ref([
  { label: 'Todos', value: null },
  { label: 'Completo', value: 'complete' },
  { label: 'Incompleto', value: 'incomplete' }
])

// Computed
const yearOptions = computed(() => {
  const currentYear = new Date().getFullYear()
  const years = [
    { label: 'Todos', value: null },
    { label: currentYear.toString(), value: currentYear },
    { label: (currentYear - 1).toString(), value: currentYear - 1 }
  ]
  return years
})

const filteredStatuses = computed(() => {
  let result = store.documentCompletionStatuses

  // Filter by pathfinder name
  if (globalFilter.value) {
    const search = globalFilter.value.toLowerCase()
    result = result.filter(s => s.pathfinder.Name.toLowerCase().includes(search))
  }

  // Filter by pathfinder type
  if (typeFilter.value) {
    result = result.filter(s => s.pathfinder.Type === typeFilter.value)
  }

  // Filter by completion status
  if (completionFilter.value) {
    if (completionFilter.value === 'complete') {
      result = result.filter(s => s.completionPercentage === 100)
    } else if (completionFilter.value === 'incomplete') {
      result = result.filter(s => s.completionPercentage < 100)
    }
  }

  // Filter by registration year
  if (yearFilter.value) {
    result = result.filter(s => s.pathfinder.RegistrationYear === yearFilter.value)
  }

  return result
})

const totalMembers = computed(() => store.pathfinders.length)
const completeCount = computed(() => store.documentCompletionStatuses.filter(s => s.completionPercentage === 100).length)
const incompleteCount = computed(() => store.documentCompletionStatuses.filter(s => s.completionPercentage < 100).length)

// Actions
const getDocumentLabel = (key: string) => {
  const doc = documentOptions.value.find(d => d.value === key)
  return doc?.label || key
}

const getDocumentStatus = (pathfinder: Pathfinder, docKey: keyof DocumentStatusMap) => {
  return pathfinder.Documents[docKey]
}

const isDocumentRequired = (pathfinder: Pathfinder, docKey: keyof DocumentStatusMap) => {
  const requiredDocs = store.getRequiredDocuments(pathfinder.Type)
  return requiredDocs.includes(docKey)
}

const toggleDocumentStatus = async (pathfinder: Pathfinder, docKey: keyof DocumentStatusMap) => {
  const currentStatus = getDocumentStatus(pathfinder, docKey)
  const newStatus = currentStatus?.status === 'received' ? 'missing' : 'received'

  loading.value = true

  try {
    await store.updateDocumentStatus(pathfinder.PK, docKey, {
      status: newStatus
    })
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: `Documento ${newStatus === 'received' ? 'marcado como recebido' : 'marcado como faltando'}`,
      life: 3000
    })
  } catch (error: any) {
    toast.add({ severity: 'error', summary: 'Erro', detail: error.message, life: 3000 })
  } finally {
    loading.value = false
  }
}

const openBulkUpdateDialog = () => {
  bulkUpdateForm.value = {
    PathfinderIds: [],
    DocumentKey: '' as keyof DocumentStatusMap,
    Status: 'received',
    Notes: ''
  }
  showBulkUpdateDialog.value = true
}

const bulkUpdateDocuments = async () => {
  if (!bulkUpdateForm.value.DocumentKey || bulkUpdateForm.value.PathfinderIds.length === 0) {
    toast.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha todos os campos obrigatórios', life: 3000 })
    return
  }

  loading.value = true

  try {
    await store.bulkUpdateDocumentStatus(
      bulkUpdateForm.value.PathfinderIds,
      bulkUpdateForm.value.DocumentKey,
      {
        status: bulkUpdateForm.value.Status,
        notes: bulkUpdateForm.value.Notes || undefined
      }
    )
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: `Documentos atualizados para ${bulkUpdateForm.value.PathfinderIds.length} membro(s)`,
      life: 3000
    })
    showBulkUpdateDialog.value = false
  } catch (error: any) {
    toast.add({ severity: 'error', summary: 'Erro', detail: error.message, life: 3000 })
  } finally {
    loading.value = false
  }
}

const getTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    'desbravador': 'Desbravador',
    'staff': 'Staff',
    'directors': 'Diretoria'
  }
  return labels[type] || type
}

const getCompletionSeverity = (percentage: number) => {
  if (percentage === 100) return 'success'
  if (percentage >= 75) return 'info'
  if (percentage >= 50) return 'warning'
  return 'danger'
}

const formatDate = (dateString?: string) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString('pt-BR')
}

const isExpiryWarning = (expiryDate?: string) => {
  if (!expiryDate) return false
  const expiry = new Date(expiryDate)
  const now = new Date()
  const diffDays = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  return diffDays <= 60 && diffDays > 0
}

const isExpired = (expiryDate?: string) => {
  if (!expiryDate) return false
  const expiry = new Date(expiryDate)
  const now = new Date()
  return expiry < now
}

const exportReport = () => {
  store.exportDocumentReport()
  toast.add({ severity: 'success', summary: 'Sucesso', detail: 'Relatório exportado', life: 3000 })
}

onMounted(() => {
  // Data is already loaded from store initialization
})
</script>

<template>
  <div class="document-tracking">
    <div class="container">
      <!-- Header -->
      <div class="header-section">
        <h2>📋 Gestão de Documentos</h2>
        <div class="header-actions">
          <Button label="Voltar" icon="pi pi-arrow-left" class="p-button-outlined" @click="$router.push('/')" />
          <Button label="Atualizar em Massa" icon="pi pi-pencil" class="p-button-outlined" @click="openBulkUpdateDialog" />
          <Button label="Exportar Relatório" icon="pi pi-download" class="p-button-outlined" @click="exportReport" />
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="summary-cards">
        <div class="card">
          <div class="card-icon" style="background: #dbeafe; color: #2563eb">
            <i class="pi pi-users"></i>
          </div>
          <div class="card-content">
            <span class="card-label">Total de Membros</span>
            <span class="card-value">{{ totalMembers }}</span>
          </div>
        </div>

        <div class="card">
          <div class="card-icon" style="background: #d1fae5; color: #059669">
            <i class="pi pi-check-circle"></i>
          </div>
          <div class="card-content">
            <span class="card-label">Documentação Completa</span>
            <span class="card-value">{{ completeCount }}</span>
          </div>
        </div>

        <div class="card">
          <div class="card-icon" style="background: #fee2e2; color: #dc2626">
            <i class="pi pi-exclamation-triangle"></i>
          </div>
          <div class="card-content">
            <span class="card-label">Documentação Incompleta</span>
            <span class="card-value">{{ incompleteCount }}</span>
          </div>
        </div>
      </div>

      <!-- Pathfinders Document Status -->
      <div class="section">
        <div class="section-header">
          <h3>Status de Documentação</h3>
        </div>

        <!-- Filters -->
        <div class="filters">
          <span class="p-input-icon-left">
            <i class="pi pi-search" />
            <InputText v-model="globalFilter" placeholder="Buscar por nome..." style="width: 300px" />
          </span>
          <Dropdown v-model="typeFilter" :options="typeFilterOptions" optionLabel="label" optionValue="value" placeholder="Tipo" style="width: 180px" />
          <Dropdown v-model="completionFilter" :options="completionFilterOptions" optionLabel="label" optionValue="value" placeholder="Status" style="width: 180px" />
          <Dropdown v-model="yearFilter" :options="yearOptions" optionLabel="label" optionValue="value" placeholder="Ano" style="width: 150px" />
        </div>

        <DataTable
          :value="filteredStatuses"
          v-model:expandedRows="expandedRows"
          :rows="10"
          :paginator="true"
          class="p-datatable-sm"
          stripedRows
          responsiveLayout="scroll"
          dataKey="pathfinder.PK"
        >
          <Column expander style="width: 50px" />

          <Column field="pathfinder.Name" header="Nome" sortable></Column>

          <Column field="pathfinder.Type" header="Tipo" sortable>
            <template #body="{ data }">
              <Tag :value="getTypeLabel(data.pathfinder.Type)" severity="info" />
            </template>
          </Column>

          <Column field="pathfinder.RegistrationYear" header="Ano" sortable style="width: 100px">
            <template #body="{ data }">{{ data.pathfinder.RegistrationYear || '-' }}</template>
          </Column>

          <Column field="completionPercentage" header="Conclusão" sortable style="width: 200px">
            <template #body="{ data }">
              <div class="progress-container">
                <ProgressBar :value="data.completionPercentage" :showValue="false" :style="{ height: '12px' }" />
                <span class="progress-text">{{ data.completionPercentage }}%</span>
              </div>
            </template>
          </Column>

          <Column field="missingDocuments.length" header="Faltando" sortable style="width: 100px">
            <template #body="{ data }">
              <Tag v-if="data.missingDocuments.length > 0" :value="data.missingDocuments.length.toString()" severity="warning" />
              <span v-else>-</span>
            </template>
          </Column>

          <Column header="Status" sortable style="width: 120px">
            <template #body="{ data }">
              <Tag
                :value="data.completionPercentage === 100 ? 'Completo' : 'Incompleto'"
                :severity="getCompletionSeverity(data.completionPercentage)"
              />
            </template>
          </Column>

          <!-- Expanded Row: Document Checklist -->
          <template #expansion="{ data }">
            <div class="expanded-content">
              <h4>Documentos - {{ data.pathfinder.Name }}</h4>
              <div class="documents-grid">
                <div
                  v-for="doc in documentOptions"
                  :key="doc.value"
                  class="document-item"
                  :class="{
                    'not-required': !isDocumentRequired(data.pathfinder, doc.value),
                    'optional': doc.requiredFor.includes('optional')
                  }"
                >
                  <div class="document-checkbox">
                    <Checkbox
                      :modelValue="getDocumentStatus(data.pathfinder, doc.value)?.status === 'received'"
                      :binary="true"
                      :disabled="!isDocumentRequired(data.pathfinder, doc.value) && !doc.requiredFor.includes('optional')"
                      @update:modelValue="toggleDocumentStatus(data.pathfinder, doc.value)"
                    />
                    <label>{{ doc.label }}</label>
                    <Tag
                      v-if="!isDocumentRequired(data.pathfinder, doc.value) && doc.requiredFor.includes('optional')"
                      value="Opcional"
                      severity="secondary"
                      class="optional-tag"
                    />
                    <Tag
                      v-else-if="!isDocumentRequired(data.pathfinder, doc.value)"
                      value="N/A"
                      severity="secondary"
                      class="optional-tag"
                    />
                  </div>

                  <div v-if="getDocumentStatus(data.pathfinder, doc.value)" class="document-details">
                    <div class="detail-row">
                      <span class="detail-label">Status:</span>
                      <Tag
                        :value="getDocumentStatus(data.pathfinder, doc.value)?.status === 'received' ? 'Recebido' : 'Faltando'"
                        :severity="getDocumentStatus(data.pathfinder, doc.value)?.status === 'received' ? 'success' : 'danger'"
                      />
                    </div>

                    <div v-if="getDocumentStatus(data.pathfinder, doc.value)?.updatedAt" class="detail-row">
                      <span class="detail-label">Atualizado em:</span>
                      <span class="detail-value">{{ formatDate(getDocumentStatus(data.pathfinder, doc.value)?.updatedAt) }}</span>
                    </div>

                    <div v-if="doc.value === 'criminal_background' && getDocumentStatus(data.pathfinder, doc.value)?.expiryDate" class="detail-row">
                      <span class="detail-label">Validade:</span>
                      <span
                        class="detail-value"
                        :class="{
                          'text-danger': isExpired(getDocumentStatus(data.pathfinder, doc.value)?.expiryDate),
                          'text-warning': isExpiryWarning(getDocumentStatus(data.pathfinder, doc.value)?.expiryDate)
                        }"
                      >
                        {{ formatDate(getDocumentStatus(data.pathfinder, doc.value)?.expiryDate) }}
                        <i v-if="isExpired(getDocumentStatus(data.pathfinder, doc.value)?.expiryDate)" class="pi pi-exclamation-circle" v-tooltip="'Documento expirado!'"></i>
                        <i v-else-if="isExpiryWarning(getDocumentStatus(data.pathfinder, doc.value)?.expiryDate)" class="pi pi-exclamation-triangle" v-tooltip="'Documento expira em breve!'"></i>
                      </span>
                    </div>

                    <div v-if="getDocumentStatus(data.pathfinder, doc.value)?.notes" class="detail-row">
                      <span class="detail-label">Observações:</span>
                      <span class="detail-value">{{ getDocumentStatus(data.pathfinder, doc.value)?.notes }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </template>
        </DataTable>
      </div>
    </div>

    <!-- Bulk Update Dialog -->
    <Dialog v-model:visible="showBulkUpdateDialog" header="Atualizar Documentos em Massa" :modal="true" style="width: 600px">
      <div class="form-grid">
        <div class="field">
          <label for="document">Documento *</label>
          <Dropdown
            id="document"
            v-model="bulkUpdateForm.DocumentKey"
            :options="documentOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Selecione"
            style="width: 100%"
          />
        </div>

        <div class="field">
          <label for="status">Status *</label>
          <Dropdown
            id="status"
            v-model="bulkUpdateForm.Status"
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            style="width: 100%"
          />
        </div>

        <div class="field col-span-2">
          <label for="pathfinders">Membros *</label>
          <MultiSelect
            id="pathfinders"
            v-model="bulkUpdateForm.PathfinderIds"
            :options="store.pathfinders"
            optionLabel="Name"
            optionValue="PK"
            placeholder="Selecione"
            style="width: 100%"
            display="chip"
            filter
          />
        </div>

        <div class="field col-span-2">
          <label for="notes">Observações</label>
          <Textarea id="notes" v-model="bulkUpdateForm.Notes" rows="3" style="width: 100%" />
        </div>
      </div>

      <template #footer>
        <Button label="Cancelar" icon="pi pi-times" class="p-button-text" @click="showBulkUpdateDialog = false" />
        <Button label="Atualizar" icon="pi pi-check" :loading="loading" @click="bulkUpdateDocuments" />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<style scoped>
.document-tracking {
  min-height: 100vh;
  background: #f8f9fa;
}

.container {
  width: 100%;
  max-width: none;
  margin: 0;
  padding: 1rem;
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

.header-actions {
  display: flex;
  gap: 1rem;
}

.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.card {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 1rem;
}

.card-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
}

.card-content {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.card-label {
  font-size: 0.875rem;
  color: #6c757d;
  font-weight: 500;
}

.card-value {
  font-size: 1.75rem;
  font-weight: bold;
  color: #2c3e50;
}

.section {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.section-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.25rem;
}

.filters {
  display: flex;
  gap: 1rem;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}

.progress-container {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
}

.progress-container :deep(.p-progressbar) {
  flex: 1;
}

.progress-text {
  font-weight: 600;
  color: #2c3e50;
  min-width: 45px;
}

.expanded-content {
  padding: 1.5rem;
  background: #f8f9fa;
  border-radius: 0.5rem;
}

.expanded-content h4 {
  margin: 0 0 1.5rem 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.documents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.document-item {
  background: white;
  border-radius: 0.5rem;
  padding: 1rem;
  border: 2px solid #e5e7eb;
}

.document-item.not-required:not(.optional) {
  opacity: 0.5;
}

.document-checkbox {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
  font-weight: 600;
  color: #374151;
}

.optional-tag {
  margin-left: auto;
  font-size: 0.75rem;
}

.document-details {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding-top: 0.75rem;
  border-top: 1px solid #e5e7eb;
}

.detail-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.detail-label {
  color: #6c757d;
  font-weight: 500;
}

.detail-value {
  color: #374151;
}

.text-danger {
  color: #dc2626 !important;
}

.text-warning {
  color: #d97706 !important;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.25rem;
  padding: 1rem 0;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field.col-span-2 {
  grid-column: span 2;
}

.field label {
  font-weight: 600;
  color: #374151;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .header-actions {
    width: 100%;
    flex-direction: column;
  }

  .documents-grid {
    grid-template-columns: 1fr;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .field.col-span-2 {
    grid-column: span 1;
  }
}
</style>
