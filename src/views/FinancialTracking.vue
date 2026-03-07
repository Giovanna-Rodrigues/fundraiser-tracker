<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useFundraiserStore } from '@/stores/fundraiser'
import type { FeeType, PathfinderFee, PathfinderFinancialSummary } from '@/stores/fundraiser'

const toast = useToast()
const store = useFundraiserStore()

// State
const loading = ref(false)
const showFeeTypeDialog = ref(false)
const showBulkAssignDialog = ref(false)
const showAddPaymentDialog = ref(false)
const showDetailsDialog = ref(false)
const submitted = ref(false)

// Filters
const globalFilter = ref('')
const statusFilter = ref<string | null>(null)
const typeFilter = ref<string | null>(null)

// Forms
const feeTypeForm = ref({
  Name: '',
  Description: '',
  Amount: 0,
  FeeCategory: 'membership' as 'membership' | 'monthly' | 'event' | 'equipment' | 'other',
  RecurrenceType: 'one-time' as 'one-time' | 'monthly' | 'annual' | undefined,
  AppliesTo: ['desbravador', 'staff', 'directors'] as ('desbravador' | 'staff' | 'directors')[],
  DueDate: null as Date | null,
  Year: new Date().getFullYear(),
  IsActive: true
})

const bulkAssignForm = ref({
  FeeTypeId: '',
  PathfinderIds: [] as string[],
  DueDate: null as Date | null
})

const paymentForm = ref({
  PathfinderId: '',
  PathfinderFeeId: '',
  Amount: 0,
  PaymentMethod: 'cash' as 'card' | 'cash' | 'pix-church' | 'pix-qr' | '7me' | 'church',
  PaymentDate: new Date(),
  Notes: '',
  ReceiptNumber: ''
})

const editingFeeType = ref<FeeType | null>(null)
const selectedPathfinder = ref<PathfinderFinancialSummary | null>(null)

// Dropdown options
const feeCategoryOptions = ref([
  { label: 'Mensalidade', value: 'membership' },
  { label: 'Mensalidade Mensal', value: 'monthly' },
  { label: 'Evento', value: 'event' },
  { label: 'Equipamento', value: 'equipment' },
  { label: 'Outro', value: 'other' }
])

const recurrenceOptions = ref([
  { label: 'Única', value: 'one-time' },
  { label: 'Mensal', value: 'monthly' },
  { label: 'Anual', value: 'annual' }
])

const appliesToOptions = ref([
  { label: 'Desbravador', value: 'desbravador' },
  { label: 'Staff', value: 'staff' },
  { label: 'Diretoria', value: 'directors' }
])

const paymentMethodOptions = ref([
  { label: 'Cartão', value: 'card' },
  { label: 'Dinheiro', value: 'cash' },
  { label: 'Pix Igreja', value: 'pix-church' },
  { label: 'Pix QR', value: 'pix-qr' },
  { label: '7me', value: '7me' },
  { label: 'Igreja', value: 'church' }
])

const statusFilterOptions = ref([
  { label: 'Todos', value: null },
  { label: 'Pendente', value: 'pending' },
  { label: 'Parcial', value: 'partial' },
  { label: 'Em Atraso', value: 'overdue' },
  { label: 'Pago', value: 'paid' }
])

const typeFilterOptions = ref([
  { label: 'Todos', value: null },
  { label: 'Desbravador', value: 'desbravador' },
  { label: 'Staff', value: 'staff' },
  { label: 'Diretoria', value: 'directors' }
])

// Computed
const filteredSummaries = computed(() => {
  let result = store.pathfinderFinancialSummaries

  // Filter by pathfinder name
  if (globalFilter.value) {
    const search = globalFilter.value.toLowerCase()
    result = result.filter(s => s.pathfinder.Name.toLowerCase().includes(search))
  }

  // Filter by pathfinder type
  if (typeFilter.value) {
    result = result.filter(s => s.pathfinder.Type === typeFilter.value)
  }

  // Filter by payment status
  if (statusFilter.value) {
    result = result.filter(s => {
      if (statusFilter.value === 'paid') {
        return s.totalAmountRemaining === 0 && s.totalFeesAssigned > 0
      } else if (statusFilter.value === 'pending') {
        return s.totalAmountRemaining > 0 && s.overdueFeesCount === 0 && s.totalAmountPaid === 0
      } else if (statusFilter.value === 'partial') {
        return s.totalAmountRemaining > 0 && s.totalAmountPaid > 0 && s.overdueFeesCount === 0
      } else if (statusFilter.value === 'overdue') {
        return s.overdueFeesCount > 0
      }
      return true
    })
  }

  return result
})

const activePathfindersForAssignment = computed(() => {
  return store.pathfinders.filter(p => p.IsActive)
})

// Actions
const openAddFeeTypeDialog = () => {
  editingFeeType.value = null
  resetFeeTypeForm()
  submitted.value = false
  showFeeTypeDialog.value = true
}

const openEditFeeTypeDialog = (feeType: FeeType) => {
  editingFeeType.value = feeType
  feeTypeForm.value = {
    Name: feeType.Name,
    Description: feeType.Description || '',
    Amount: feeType.Amount,
    FeeCategory: feeType.FeeCategory,
    RecurrenceType: feeType.RecurrenceType,
    AppliesTo: feeType.AppliesTo,
    DueDate: feeType.DueDate ? new Date(feeType.DueDate) : null,
    Year: feeType.Year || new Date().getFullYear(),
    IsActive: feeType.IsActive
  }
  submitted.value = false
  showFeeTypeDialog.value = true
}

const saveFeeType = async () => {
  submitted.value = true

  if (!feeTypeForm.value.Name || feeTypeForm.value.Amount <= 0) {
    return
  }

  loading.value = true

  try {
    const data = {
      Name: feeTypeForm.value.Name,
      Description: feeTypeForm.value.Description || undefined,
      Amount: feeTypeForm.value.Amount,
      FeeCategory: feeTypeForm.value.FeeCategory,
      RecurrenceType: feeTypeForm.value.RecurrenceType,
      AppliesTo: feeTypeForm.value.AppliesTo,
      DueDate: feeTypeForm.value.DueDate ? feeTypeForm.value.DueDate.toISOString().split('T')[0] : undefined,
      Year: feeTypeForm.value.Year,
      IsActive: feeTypeForm.value.IsActive
    }

    if (editingFeeType.value) {
      await store.updateFeeType(editingFeeType.value.PK, data)
      toast.add({ severity: 'success', summary: 'Sucesso', detail: 'Tipo de taxa atualizado', life: 3000 })
    } else {
      await store.addFeeType(data)
      toast.add({ severity: 'success', summary: 'Sucesso', detail: 'Tipo de taxa criado', life: 3000 })
    }

    showFeeTypeDialog.value = false
  } catch (error: any) {
    toast.add({ severity: 'error', summary: 'Erro', detail: error.message, life: 3000 })
  } finally {
    loading.value = false
  }
}

const deleteFeeType = async (feeType: FeeType) => {
  if (!confirm(`Tem certeza que deseja excluir o tipo de taxa "${feeType.Name}"?`)) {
    return
  }

  try {
    await store.deleteFeeType(feeType.PK)
    toast.add({ severity: 'success', summary: 'Sucesso', detail: 'Tipo de taxa excluído', life: 3000 })
  } catch (error: any) {
    toast.add({ severity: 'error', summary: 'Erro', detail: error.message, life: 3000 })
  }
}

const openBulkAssignDialog = () => {
  bulkAssignForm.value = {
    FeeTypeId: '',
    PathfinderIds: [],
    DueDate: null
  }
  submitted.value = false
  showBulkAssignDialog.value = true
}

const bulkAssignFee = async () => {
  submitted.value = true

  if (!bulkAssignForm.value.FeeTypeId || bulkAssignForm.value.PathfinderIds.length === 0 || !bulkAssignForm.value.DueDate) {
    return
  }

  loading.value = true

  try {
    const dueDate = bulkAssignForm.value.DueDate.toISOString().split('T')[0]
    await store.bulkAssignFee(bulkAssignForm.value.FeeTypeId, bulkAssignForm.value.PathfinderIds, dueDate)
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: `Taxa atribuída a ${bulkAssignForm.value.PathfinderIds.length} desbravador(es)`,
      life: 3000
    })
    showBulkAssignDialog.value = false
  } catch (error: any) {
    toast.add({ severity: 'error', summary: 'Erro', detail: error.message, life: 3000 })
  } finally {
    loading.value = false
  }
}

const openAddPaymentDialog = (summary: PathfinderFinancialSummary, fee?: PathfinderFee) => {
  paymentForm.value = {
    PathfinderId: summary.pathfinder.PK,
    PathfinderFeeId: fee?.PK || '',
    Amount: fee?.AmountRemaining || 0,
    PaymentMethod: 'cash',
    PaymentDate: new Date(),
    Notes: '',
    ReceiptNumber: ''
  }
  submitted.value = false
  showAddPaymentDialog.value = true
}

const addPayment = async () => {
  submitted.value = true

  if (!paymentForm.value.PathfinderFeeId || paymentForm.value.Amount <= 0) {
    return
  }

  loading.value = true

  try {
    await store.addPayment({
      PathfinderId: paymentForm.value.PathfinderId,
      PathfinderFeeId: paymentForm.value.PathfinderFeeId,
      Amount: paymentForm.value.Amount,
      PaymentMethod: paymentForm.value.PaymentMethod,
      PaymentDate: paymentForm.value.PaymentDate.toISOString().split('T')[0],
      Notes: paymentForm.value.Notes || undefined,
      ReceiptNumber: paymentForm.value.ReceiptNumber || undefined
    })
    toast.add({ severity: 'success', summary: 'Sucesso', detail: 'Pagamento registrado', life: 3000 })
    showAddPaymentDialog.value = false
  } catch (error: any) {
    toast.add({ severity: 'error', summary: 'Erro', detail: error.message, life: 3000 })
  } finally {
    loading.value = false
  }
}

const openDetailsDialog = (summary: PathfinderFinancialSummary) => {
  selectedPathfinder.value = summary
  showDetailsDialog.value = true
}

const getStatusSeverity = (summary: PathfinderFinancialSummary) => {
  if (summary.overdueFeesCount > 0) return 'danger'
  if (summary.totalAmountRemaining === 0 && summary.totalFeesAssigned > 0) return 'success'
  if (summary.totalAmountPaid > 0) return 'warning'
  return 'info'
}

const getStatusLabel = (summary: PathfinderFinancialSummary) => {
  if (summary.overdueFeesCount > 0) return 'Em Atraso'
  if (summary.totalAmountRemaining === 0 && summary.totalFeesAssigned > 0) return 'Em Dia'
  if (summary.totalAmountPaid > 0) return 'Parcial'
  return 'Pendente'
}

const getTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    'desbravador': 'Desbravador',
    'staff': 'Staff',
    'directors': 'Diretoria'
  }
  return labels[type] || type
}

const formatCurrency = (value: number) => {
  return `R$ ${value.toFixed(2).replace('.', ',')}`
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('pt-BR')
}

const resetFeeTypeForm = () => {
  feeTypeForm.value = {
    Name: '',
    Description: '',
    Amount: 0,
    FeeCategory: 'membership',
    RecurrenceType: 'one-time',
    AppliesTo: ['desbravador', 'staff', 'directors'],
    DueDate: null,
    Year: new Date().getFullYear(),
    IsActive: true
  }
}

const exportReport = () => {
  store.exportFinancialReport()
  toast.add({ severity: 'success', summary: 'Sucesso', detail: 'Relatório exportado', life: 3000 })
}

onMounted(() => {
  // Data is already loaded from store initialization
})
</script>

<template>
  <div class="financial-tracking">
    <div class="container">
      <!-- Header -->
      <div class="header-section">
        <h2>💰 Gestão Financeira</h2>
        <div class="header-actions">
          <Button label="Voltar" icon="pi pi-arrow-left" class="p-button-outlined" @click="$router.push('/')" />
          <Button label="Exportar Relatório" icon="pi pi-download" class="p-button-outlined" @click="exportReport" />
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="summary-cards">
        <div class="card">
          <div class="card-icon" style="background: #fee2e2; color: #dc2626">
            <i class="pi pi-exclamation-circle"></i>
          </div>
          <div class="card-content">
            <span class="card-label">Saldo Devedor</span>
            <span class="card-value">{{ formatCurrency(store.totalOutstandingBalance) }}</span>
          </div>
        </div>

        <div class="card">
          <div class="card-icon" style="background: #d1fae5; color: #059669">
            <i class="pi pi-check-circle"></i>
          </div>
          <div class="card-content">
            <span class="card-label">Total Arrecadado</span>
            <span class="card-value">{{ formatCurrency(store.totalCollected) }}</span>
          </div>
        </div>

        <div class="card">
          <div class="card-icon" style="background: #fef3c7; color: #d97706">
            <i class="pi pi-clock"></i>
          </div>
          <div class="card-content">
            <span class="card-label">Taxas em Atraso</span>
            <span class="card-value">{{ store.overdueFeesCount }}</span>
          </div>
        </div>
      </div>

      <!-- Fee Types Management -->
      <div class="section">
        <div class="section-header">
          <h3>Tipos de Taxas</h3>
          <Button label="Adicionar Tipo" icon="pi pi-plus" @click="openAddFeeTypeDialog" size="small" />
        </div>

        <DataTable :value="store.feeTypes" :rows="5" :paginator="true" class="p-datatable-sm" stripedRows>
          <Column field="Name" header="Nome" sortable></Column>
          <Column field="Amount" header="Valor" sortable>
            <template #body="{ data }">{{ formatCurrency(data.Amount) }}</template>
          </Column>
          <Column field="FeeCategory" header="Categoria" sortable>
            <template #body="{ data }">
              <Tag :value="feeCategoryOptions.find(o => o.value === data.FeeCategory)?.label" severity="info" />
            </template>
          </Column>
          <Column field="DueDate" header="Vencimento" sortable>
            <template #body="{ data }">{{ data.DueDate ? formatDate(data.DueDate) : '-' }}</template>
          </Column>
          <Column field="IsActive" header="Status" sortable>
            <template #body="{ data }">
              <Tag :value="data.IsActive ? 'Ativo' : 'Inativo'" :severity="data.IsActive ? 'success' : 'danger'" />
            </template>
          </Column>
          <Column header="Ações" style="width: 150px">
            <template #body="{ data }">
              <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openEditFeeTypeDialog(data)" v-tooltip.top="'Editar'" />
              <Button icon="pi pi-users" class="p-button-text p-button-sm" @click="bulkAssignForm.FeeTypeId = data.PK; openBulkAssignDialog()" v-tooltip.top="'Atribuir em Massa'" />
              <Button icon="pi pi-trash" class="p-button-text p-button-danger p-button-sm" @click="deleteFeeType(data)" v-tooltip.top="'Excluir'" />
            </template>
          </Column>
        </DataTable>
      </div>

      <!-- Pathfinders Financial Summary -->
      <div class="section">
        <div class="section-header">
          <h3>Desbravadores</h3>
        </div>

        <!-- Filters -->
        <div class="filters">
          <span class="p-input-icon-left">
            <i class="pi pi-search" />
            <InputText v-model="globalFilter" placeholder="Buscar por nome..." style="width: 300px" />
          </span>
          <Dropdown v-model="typeFilter" :options="typeFilterOptions" optionLabel="label" optionValue="value" placeholder="Tipo" style="width: 180px" />
          <Dropdown v-model="statusFilter" :options="statusFilterOptions" optionLabel="label" optionValue="value" placeholder="Status" style="width: 180px" />
        </div>

        <DataTable :value="filteredSummaries" :rows="10" :paginator="true" class="p-datatable-sm" stripedRows responsiveLayout="scroll">
          <Column field="pathfinder.Name" header="Nome" sortable></Column>
          <Column field="pathfinder.Type" header="Tipo" sortable>
            <template #body="{ data }">
              <Tag :value="getTypeLabel(data.pathfinder.Type)" severity="info" />
            </template>
          </Column>
          <Column field="totalAmountOwed" header="Total Devido" sortable>
            <template #body="{ data }">{{ formatCurrency(data.totalAmountOwed) }}</template>
          </Column>
          <Column field="totalAmountPaid" header="Pago" sortable>
            <template #body="{ data }">{{ formatCurrency(data.totalAmountPaid) }}</template>
          </Column>
          <Column field="totalAmountRemaining" header="Restante" sortable>
            <template #body="{ data }">
              <strong :class="{ 'text-danger': data.totalAmountRemaining > 0 }">
                {{ formatCurrency(data.totalAmountRemaining) }}
              </strong>
            </template>
          </Column>
          <Column field="overdueFeesCount" header="Em Atraso" sortable>
            <template #body="{ data }">
              <Tag v-if="data.overdueFeesCount > 0" :value="data.overdueFeesCount.toString()" severity="danger" />
              <span v-else>-</span>
            </template>
          </Column>
          <Column header="Status" sortable>
            <template #body="{ data }">
              <Tag :value="getStatusLabel(data)" :severity="getStatusSeverity(data)" />
            </template>
          </Column>
          <Column header="Ações" style="width: 150px">
            <template #body="{ data }">
              <Button icon="pi pi-eye" class="p-button-text p-button-sm" @click="openDetailsDialog(data)" v-tooltip.top="'Ver Detalhes'" />
              <Button icon="pi pi-dollar" class="p-button-text p-button-success p-button-sm" @click="openAddPaymentDialog(data)" v-tooltip.top="'Adicionar Pagamento'" />
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Fee Type Dialog -->
    <Dialog v-model:visible="showFeeTypeDialog" :header="editingFeeType ? 'Editar Tipo de Taxa' : 'Novo Tipo de Taxa'" :modal="true" style="width: 600px">
      <div class="form-grid">
        <div class="field">
          <label for="name">Nome *</label>
          <InputText id="name" v-model="feeTypeForm.Name" :class="{ 'p-invalid': submitted && !feeTypeForm.Name }" style="width: 100%" />
        </div>

        <div class="field">
          <label for="amount">Valor *</label>
          <InputNumber id="amount" v-model="feeTypeForm.Amount" mode="currency" currency="BRL" locale="pt-BR" :class="{ 'p-invalid': submitted && feeTypeForm.Amount <= 0 }" style="width: 100%" />
        </div>

        <div class="field">
          <label for="category">Categoria *</label>
          <Dropdown id="category" v-model="feeTypeForm.FeeCategory" :options="feeCategoryOptions" optionLabel="label" optionValue="value" style="width: 100%" />
        </div>

        <div class="field">
          <label for="recurrence">Recorrência</label>
          <Dropdown id="recurrence" v-model="feeTypeForm.RecurrenceType" :options="recurrenceOptions" optionLabel="label" optionValue="value" style="width: 100%" />
        </div>

        <div class="field">
          <label for="appliesTo">Aplica-se a *</label>
          <MultiSelect id="appliesTo" v-model="feeTypeForm.AppliesTo" :options="appliesToOptions" optionLabel="label" optionValue="value" placeholder="Selecione" style="width: 100%" />
        </div>

        <div class="field">
          <label for="dueDate">Data de Vencimento</label>
          <Calendar id="dueDate" v-model="feeTypeForm.DueDate" dateFormat="dd/mm/yy" style="width: 100%" />
        </div>

        <div class="field col-span-2">
          <label for="description">Descrição</label>
          <Textarea id="description" v-model="feeTypeForm.Description" rows="3" style="width: 100%" />
        </div>
      </div>

      <template #footer>
        <Button label="Cancelar" icon="pi pi-times" class="p-button-text" @click="showFeeTypeDialog = false" />
        <Button label="Salvar" icon="pi pi-check" :loading="loading" @click="saveFeeType" />
      </template>
    </Dialog>

    <!-- Bulk Assign Fee Dialog -->
    <Dialog v-model:visible="showBulkAssignDialog" header="Atribuir Taxa em Massa" :modal="true" style="width: 600px">
      <div class="form-grid">
        <div class="field">
          <label for="feeType">Tipo de Taxa *</label>
          <Dropdown id="feeType" v-model="bulkAssignForm.FeeTypeId" :options="store.feeTypes" optionLabel="Name" optionValue="PK" placeholder="Selecione" :class="{ 'p-invalid': submitted && !bulkAssignForm.FeeTypeId }" style="width: 100%" />
        </div>

        <div class="field">
          <label for="dueDate">Data de Vencimento *</label>
          <Calendar id="dueDate" v-model="bulkAssignForm.DueDate" dateFormat="dd/mm/yy" :class="{ 'p-invalid': submitted && !bulkAssignForm.DueDate }" style="width: 100%" />
        </div>

        <div class="field col-span-2">
          <label for="pathfinders">Desbravadores *</label>
          <MultiSelect id="pathfinders" v-model="bulkAssignForm.PathfinderIds" :options="activePathfindersForAssignment" optionLabel="Name" optionValue="PK" placeholder="Selecione" :class="{ 'p-invalid': submitted && bulkAssignForm.PathfinderIds.length === 0 }" style="width: 100%" display="chip" filter />
        </div>
      </div>

      <template #footer>
        <Button label="Cancelar" icon="pi pi-times" class="p-button-text" @click="showBulkAssignDialog = false" />
        <Button label="Atribuir" icon="pi pi-check" :loading="loading" @click="bulkAssignFee" />
      </template>
    </Dialog>

    <!-- Add Payment Dialog -->
    <Dialog v-model:visible="showAddPaymentDialog" header="Registrar Pagamento" :modal="true" style="width: 500px">
      <div class="form-grid">
        <div class="field col-span-2">
          <label for="fee">Taxa *</label>
          <Dropdown id="fee" v-model="paymentForm.PathfinderFeeId" :options="selectedPathfinder?.fees || []" optionLabel="feeType.Name" optionValue="PK" placeholder="Selecione" :class="{ 'p-invalid': submitted && !paymentForm.PathfinderFeeId }" style="width: 100%">
            <template #option="{ option }">
              <div>
                <div>{{ option.feeType?.Name }} - {{ formatCurrency(option.AmountRemaining) }} restante</div>
                <small>Vencimento: {{ formatDate(option.DueDate) }}</small>
              </div>
            </template>
          </Dropdown>
        </div>

        <div class="field">
          <label for="amount">Valor *</label>
          <InputNumber id="amount" v-model="paymentForm.Amount" mode="currency" currency="BRL" locale="pt-BR" :class="{ 'p-invalid': submitted && paymentForm.Amount <= 0 }" style="width: 100%" />
        </div>

        <div class="field">
          <label for="paymentMethod">Forma de Pagamento *</label>
          <Dropdown id="paymentMethod" v-model="paymentForm.PaymentMethod" :options="paymentMethodOptions" optionLabel="label" optionValue="value" style="width: 100%" />
        </div>

        <div class="field">
          <label for="paymentDate">Data do Pagamento *</label>
          <Calendar id="paymentDate" v-model="paymentForm.PaymentDate" dateFormat="dd/mm/yy" style="width: 100%" />
        </div>

        <div class="field">
          <label for="receiptNumber">Número do Recibo</label>
          <InputText id="receiptNumber" v-model="paymentForm.ReceiptNumber" style="width: 100%" />
        </div>

        <div class="field col-span-2">
          <label for="notes">Observações</label>
          <Textarea id="notes" v-model="paymentForm.Notes" rows="2" style="width: 100%" />
        </div>
      </div>

      <template #footer>
        <Button label="Cancelar" icon="pi pi-times" class="p-button-text" @click="showAddPaymentDialog = false" />
        <Button label="Registrar" icon="pi pi-check" :loading="loading" @click="addPayment" />
      </template>
    </Dialog>

    <!-- Details Dialog -->
    <Dialog v-model:visible="showDetailsDialog" :header="`Detalhes - ${selectedPathfinder?.pathfinder.Name}`" :modal="true" style="width: 800px">
      <div v-if="selectedPathfinder" class="details-content">
        <div class="details-summary">
          <div class="detail-item">
            <span class="detail-label">Total Devido:</span>
            <span class="detail-value">{{ formatCurrency(selectedPathfinder.totalAmountOwed) }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Total Pago:</span>
            <span class="detail-value text-success">{{ formatCurrency(selectedPathfinder.totalAmountPaid) }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Saldo:</span>
            <span class="detail-value text-danger">{{ formatCurrency(selectedPathfinder.totalAmountRemaining) }}</span>
          </div>
        </div>

        <Divider />

        <h4>Taxas</h4>
        <DataTable :value="selectedPathfinder.fees" class="p-datatable-sm" stripedRows>
          <Column field="feeType.Name" header="Taxa"></Column>
          <Column field="DueDate" header="Vencimento">
            <template #body="{ data }">{{ formatDate(data.DueDate) }}</template>
          </Column>
          <Column field="Amount" header="Valor">
            <template #body="{ data }">{{ formatCurrency(data.Amount) }}</template>
          </Column>
          <Column field="AmountPaid" header="Pago">
            <template #body="{ data }">{{ formatCurrency(data.AmountPaid) }}</template>
          </Column>
          <Column field="AmountRemaining" header="Restante">
            <template #body="{ data }">{{ formatCurrency(data.AmountRemaining) }}</template>
          </Column>
          <Column field="Status" header="Status">
            <template #body="{ data }">
              <Tag :value="data.Status" :severity="data.Status === 'paid' ? 'success' : data.Status === 'overdue' ? 'danger' : 'warning'" />
            </template>
          </Column>
        </DataTable>
      </div>
    </Dialog>

    <Toast />
  </div>
</template>

<style scoped>
.financial-tracking {
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
  margin-bottom: 2rem;
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

.details-content {
  padding: 1rem 0;
}

.details-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  margin-bottom: 1rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.detail-label {
  font-size: 0.875rem;
  color: #6c757d;
  font-weight: 500;
}

.detail-value {
  font-size: 1.25rem;
  font-weight: bold;
  color: #2c3e50;
}

.text-success {
  color: #059669 !important;
}

.text-danger {
  color: #dc2626 !important;
}

@media (max-width: 768px) {
  .header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .header-actions {
    width: 100%;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .field.col-span-2 {
    grid-column: span 1;
  }

  .details-summary {
    grid-template-columns: 1fr;
  }
}
</style>
