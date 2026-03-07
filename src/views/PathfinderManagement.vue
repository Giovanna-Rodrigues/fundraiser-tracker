<script setup lang="ts">
import { ref, computed } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { Pathfinder, DocumentStatusMap } from '@/stores/fundraiser'

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
  Name: '',
  Type: 'desbravador' as 'desbravador' | 'staff' | 'directors',
  Email: '',
  Phone: '',
  ParentName: '',
  ParentEmail: '',
  ParentPhone: '',
  BirthDate: null as Date | null,
  Address: '',
  Notes: '',
  IsActive: true,
  RegistrationYear: new Date().getFullYear()
})

const typeOptions = ref([
  { label: 'Desbravador', value: 'desbravador' },
  { label: 'Staff', value: 'staff' },
  { label: 'Diretoria', value: 'directors' }
])

// Computed
const pathfinders = fundraiserStore.pathfinders
const expandedRows = ref<any[]>([])

const documentOptions = [
  { label: 'RG + CPF', value: 'id_cpf' as keyof DocumentStatusMap },
  { label: 'Cartão SUS', value: 'sus_card' as keyof DocumentStatusMap },
  { label: 'Comprovante de Residência', value: 'proof_residence' as keyof DocumentStatusMap },
  { label: 'RG + CPF dos Pais', value: 'parent_id_cpf' as keyof DocumentStatusMap },
  { label: 'Cartão de Vacinação', value: 'vaccination_card' as keyof DocumentStatusMap },
  { label: 'Antecedentes Criminais', value: 'criminal_background' as keyof DocumentStatusMap },
  { label: 'Cartão de Plano de Saúde', value: 'health_insurance' as keyof DocumentStatusMap }
]

const getDocumentStatus = (pathfinder: Pathfinder) => {
  return fundraiserStore.documentCompletionStatuses.find(s => s.pathfinder.PK === pathfinder.PK)
}

const getFinancialSummary = (pathfinder: Pathfinder) => {
  return fundraiserStore.pathfinderFinancialSummaries.find(s => s.pathfinder.PK === pathfinder.PK)
}

const getPathfinderOrders = (pathfinder: Pathfinder) => {
  return fundraiserStore.orders.filter(o => o.PathfinderId === pathfinder.PK)
    .sort((a, b) => new Date(b.CreatedAt).getTime() - new Date(a.CreatedAt).getTime())
    .slice(0, 10)
}

const isDocumentRequired = (pathfinder: Pathfinder, docKey: keyof DocumentStatusMap) => {
  return fundraiserStore.getRequiredDocuments(pathfinder.Type).includes(docKey)
}

// Methods
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('pt-BR')
}

const getTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    'desbravador': 'Desbravador',
    'staff': 'Staff',
    'directors': 'Diretoria'
  }
  return labels[type] || type
}

const hideDialog = () => {
  showAddDialog.value = false
  submitted.value = false
  editingPathfinder.value = null
  pathfinderForm.value = {
    Name: '',
    Type: 'desbravador',
    Email: '',
    Phone: '',
    ParentName: '',
    ParentEmail: '',
    ParentPhone: '',
    BirthDate: null,
    Address: '',
    Notes: '',
    IsActive: true,
    RegistrationYear: new Date().getFullYear()
  }
}

const editPathfinder = (pathfinder: Pathfinder) => {
  editingPathfinder.value = pathfinder
  pathfinderForm.value = {
    Name: pathfinder.Name,
    Type: pathfinder.Type || 'desbravador',
    Email: pathfinder.Email || '',
    Phone: pathfinder.Phone || '',
    ParentName: pathfinder.ParentName || '',
    ParentEmail: pathfinder.ParentEmail || '',
    ParentPhone: pathfinder.ParentPhone || '',
    BirthDate: pathfinder.BirthDate ? new Date(pathfinder.BirthDate) : null,
    Address: pathfinder.Address || '',
    Notes: pathfinder.Notes || '',
    IsActive: pathfinder.IsActive !== undefined ? pathfinder.IsActive : true,
    RegistrationYear: pathfinder.RegistrationYear || new Date().getFullYear()
  }
  showAddDialog.value = true
}

const savePathfinder = async () => {
  submitted.value = true

  if (!pathfinderForm.value.Name?.trim()) {
    return
  }

  try {
    const data = {
      Name: pathfinderForm.value.Name.trim(),
      Type: pathfinderForm.value.Type,
      Email: pathfinderForm.value.Email?.trim() || undefined,
      Phone: pathfinderForm.value.Phone?.trim() || undefined,
      ParentName: pathfinderForm.value.ParentName?.trim() || undefined,
      ParentEmail: pathfinderForm.value.ParentEmail?.trim() || undefined,
      ParentPhone: pathfinderForm.value.ParentPhone?.trim() || undefined,
      BirthDate: pathfinderForm.value.BirthDate ? pathfinderForm.value.BirthDate.toISOString().split('T')[0] : undefined,
      Address: pathfinderForm.value.Address?.trim() || undefined,
      Notes: pathfinderForm.value.Notes?.trim() || undefined,
      IsActive: pathfinderForm.value.IsActive,
      RegistrationYear: pathfinderForm.value.RegistrationYear,
      Documents: {} // Initialize with empty documents object
    }

    if (editingPathfinder.value) {
      await fundraiserStore.updatePathfinder(editingPathfinder.value.PK, data)
      toast.add({
        severity: 'success',
        summary: 'Sucesso',
        detail: 'Desbravador atualizado com sucesso',
        life: 3000
      })
    } else {
      await fundraiserStore.addPathfinder(data)
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

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0)

const getOrderStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    pending: 'Pendente', preparing: 'Preparando', ready: 'Pronto',
    delivered: 'Entregue', not_picked_up: 'Não Retirado'
  }
  return labels[status] || status
}

const getOrderStatusSeverity = (status: string) => {
  const map: Record<string, string> = {
    pending: 'warning', preparing: 'info', ready: 'success',
    delivered: 'success', not_picked_up: 'danger'
  }
  return map[status] || 'info'
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
</script>

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
        v-model:expandedRows="expandedRows"
        :paginator="true"
        :rows="10"
        dataKey="PK"
        :loading="loading"
        class="p-datatable-gridlines"
      >
        <Column expander style="width: 3rem" />
        <Column field="Name" header="Nome" sortable></Column>
        <Column field="Type" header="Tipo" sortable>
          <template #body="{ data }">
            <Tag :value="getTypeLabel(data.Type || 'desbravador')" severity="info" />
          </template>
        </Column>
        <Column field="Email" header="Email" sortable></Column>
        <Column field="Phone" header="Telefone" sortable></Column>
        <Column field="IsActive" header="Status" sortable>
          <template #body="{ data }">
            <Tag
              :value="data.IsActive !== false ? 'Ativo' : 'Inativo'"
              :severity="data.IsActive !== false ? 'success' : 'danger'"
            />
          </template>
        </Column>
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

        <!-- Expandable detail panel -->
        <template #expansion="{ data }">
          <div class="detail-panel">
            <TabView>
              <!-- Documents Tab -->
              <TabPanel header="Documentos">
                <div v-if="getDocumentStatus(data) as any" class="doc-panel">
                  <div class="doc-progress-row">
                    <span class="doc-pct-label">Conclusão: {{ getDocumentStatus(data)?.completionPercentage }}%</span>
                    <ProgressBar :value="getDocumentStatus(data)?.completionPercentage" :showValue="false" style="flex:1; height:10px" />
                  </div>
                  <div class="doc-grid">
                    <div
                      v-for="doc in documentOptions"
                      :key="doc.value"
                      class="doc-item"
                      :class="{ 'doc-na': !isDocumentRequired(data, doc.value) }"
                    >
                      <i
                        class="pi"
                        :class="data.Documents[doc.value]?.status === 'received' ? 'pi-check-circle doc-ok' : 'pi-times-circle doc-missing'"
                      ></i>
                      <span class="doc-name">{{ doc.label }}</span>
                      <Tag v-if="!isDocumentRequired(data, doc.value)" value="N/A" severity="secondary" style="font-size:0.7rem" />
                    </div>
                  </div>
                  <div v-if="(getDocumentStatus(data)?.missingDocuments?.length ?? 0) > 0" class="missing-docs">
                    <i class="pi pi-exclamation-triangle"></i>
                    Faltando: {{ getDocumentStatus(data)?.missingDocuments?.join(', ') }}
                  </div>
                </div>
                <p v-else class="no-data">Nenhuma informação de documentos disponível.</p>
              </TabPanel>

              <!-- Financial Tab -->
              <TabPanel header="Financeiro">
                <div v-if="getFinancialSummary(data)" class="fin-panel">
                  <div class="fin-cards">
                    <div class="fin-card">
                      <span class="fin-label">Total Devido</span>
                      <span class="fin-value">{{ formatCurrency(getFinancialSummary(data)!.totalAmountOwed) }}</span>
                    </div>
                    <div class="fin-card fin-ok">
                      <span class="fin-label">Total Pago</span>
                      <span class="fin-value">{{ formatCurrency(getFinancialSummary(data)!.totalAmountPaid) }}</span>
                    </div>
                    <div class="fin-card" :class="getFinancialSummary(data)!.totalAmountRemaining > 0 ? 'fin-warn' : 'fin-ok'">
                      <span class="fin-label">Saldo Restante</span>
                      <span class="fin-value">{{ formatCurrency(getFinancialSummary(data)!.totalAmountRemaining) }}</span>
                    </div>
                    <div v-if="getFinancialSummary(data)!.overdueFeesCount > 0" class="fin-card fin-danger">
                      <span class="fin-label">Em Atraso</span>
                      <span class="fin-value">{{ getFinancialSummary(data)!.overdueFeesCount }} taxa(s)</span>
                    </div>
                  </div>
                  <div v-if="getFinancialSummary(data)!.fees.length > 0" class="fin-fees">
                    <DataTable :value="getFinancialSummary(data)!.fees" class="p-datatable-sm" stripedRows>
                      <Column field="feeType.Name" header="Taxa"></Column>
                      <Column field="DueDate" header="Vencimento">
                        <template #body="{ data: fee }">{{ formatDate(fee.DueDate) }}</template>
                      </Column>
                      <Column field="Amount" header="Valor">
                        <template #body="{ data: fee }">{{ formatCurrency(fee.Amount) }}</template>
                      </Column>
                      <Column field="AmountPaid" header="Pago">
                        <template #body="{ data: fee }">{{ formatCurrency(fee.AmountPaid) }}</template>
                      </Column>
                      <Column field="Status" header="Status">
                        <template #body="{ data: fee }">
                          <Tag :value="fee.Status" :severity="fee.Status === 'paid' ? 'success' : fee.Status === 'overdue' ? 'danger' : 'warning'" />
                        </template>
                      </Column>
                    </DataTable>
                  </div>
                  <p v-else class="no-data">Nenhuma taxa atribuída.</p>
                </div>
                <p v-else class="no-data">Nenhuma informação financeira disponível.</p>
              </TabPanel>

              <!-- Orders Tab -->
              <TabPanel header="Pedidos">
                <div v-if="getPathfinderOrders(data).length > 0">
                  <DataTable :value="getPathfinderOrders(data)" class="p-datatable-sm" stripedRows>
                    <Column field="Date" header="Data">
                      <template #body="{ data: order }">{{ formatDate(order.Date) }}</template>
                    </Column>
                    <Column field="CustomerName" header="Cliente"></Column>
                    <Column field="TotalAmount" header="Total">
                      <template #body="{ data: order }">{{ formatCurrency(order.TotalAmount) }}</template>
                    </Column>
                    <Column field="PaymentMethod" header="Pagamento">
                      <template #body="{ data: order }">
                        <Tag v-if="order.PaymentMethod" :value="order.PaymentMethod" severity="success" />
                        <Tag v-else value="Pagar depois" severity="warning" />
                      </template>
                    </Column>
                    <Column field="Status" header="Status">
                      <template #body="{ data: order }">
                        <Tag :value="getOrderStatusLabel(order.Status)" :severity="getOrderStatusSeverity(order.Status)" />
                      </template>
                    </Column>
                  </DataTable>
                </div>
                <p v-else class="no-data">Nenhum pedido encontrado.</p>
              </TabPanel>
            </TabView>
          </div>
        </template>
      </DataTable>
    </div>

    <!-- Add/Edit Dialog -->
    <Dialog
      v-model:visible="showAddDialog"
      :header="editingPathfinder ? 'Editar Desbravador' : 'Novo Desbravador'"
      :modal="true"
      style="width: 700px"
    >
      <div class="dialog-content">
        <div class="form-grid">
          <!-- Basic Information -->
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

          <div class="field">
            <label for="type">Tipo *</label>
            <Dropdown
              id="type"
              v-model="pathfinderForm.Type"
              :options="typeOptions"
              optionLabel="label"
              optionValue="value"
              style="width: 100%"
            />
          </div>

          <div class="field">
            <label for="email">Email</label>
            <InputText
              id="email"
              v-model="pathfinderForm.Email"
              type="email"
              style="width: 100%"
            />
          </div>

          <div class="field">
            <label for="phone">Telefone</label>
            <InputText
              id="phone"
              v-model="pathfinderForm.Phone"
              style="width: 100%"
            />
          </div>

          <div class="field">
            <label for="birthDate">Data de Nascimento</label>
            <Calendar
              id="birthDate"
              v-model="pathfinderForm.BirthDate"
              dateFormat="dd/mm/yy"
              style="width: 100%"
            />
          </div>

          <div class="field">
            <label for="registrationYear">Ano de Registro</label>
            <InputNumber
              id="registrationYear"
              v-model="pathfinderForm.RegistrationYear"
              :useGrouping="false"
              style="width: 100%"
            />
          </div>

          <!-- Parent Information (shown for Desbravador) -->
          <template v-if="pathfinderForm.Type === 'desbravador'">
            <div class="field col-span-2">
              <Divider align="left">
                <span class="divider-text">Informações dos Pais/Responsáveis</span>
              </Divider>
            </div>

            <div class="field">
              <label for="parentName">Nome do Responsável</label>
              <InputText
                id="parentName"
                v-model="pathfinderForm.ParentName"
                style="width: 100%"
              />
            </div>

            <div class="field">
              <label for="parentEmail">Email do Responsável</label>
              <InputText
                id="parentEmail"
                v-model="pathfinderForm.ParentEmail"
                type="email"
                style="width: 100%"
              />
            </div>

            <div class="field col-span-2">
              <label for="parentPhone">Telefone do Responsável</label>
              <InputText
                id="parentPhone"
                v-model="pathfinderForm.ParentPhone"
                style="width: 100%"
              />
            </div>
          </template>

          <!-- Other Information -->
          <div class="field col-span-2">
            <Divider align="left">
              <span class="divider-text">Outras Informações</span>
            </Divider>
          </div>

          <div class="field col-span-2">
            <label for="address">Endereço</label>
            <InputText
              id="address"
              v-model="pathfinderForm.Address"
              style="width: 100%"
            />
          </div>

          <div class="field col-span-2">
            <label for="notes">Observações</label>
            <Textarea
              id="notes"
              v-model="pathfinderForm.Notes"
              rows="3"
              style="width: 100%"
            />
          </div>

          <div class="field col-span-2">
            <div class="checkbox-field">
              <Checkbox
                id="isActive"
                v-model="pathfinderForm.IsActive"
                :binary="true"
              />
              <label for="isActive">Membro Ativo</label>
            </div>
          </div>
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

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.25rem;
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

.checkbox-field {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.checkbox-field label {
  margin: 0;
  cursor: pointer;
}

.divider-text {
  font-weight: 600;
  color: #2c3e50;
  font-size: 0.95rem;
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

/* ===== DETAIL PANEL ===== */
.detail-panel {
  padding: 1rem;
  background: #f8f9fa;
}

.doc-panel, .fin-panel {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.doc-progress-row {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.doc-pct-label {
  font-weight: 600;
  color: #2c3e50;
  white-space: nowrap;
  font-size: 0.9rem;
}

.doc-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 0.5rem;
}

.doc-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  background: white;
  border-radius: 0.375rem;
  font-size: 0.875rem;
}

.doc-item.doc-na {
  opacity: 0.45;
}

.doc-name {
  flex: 1;
  color: #374151;
}

.doc-ok  { color: #22c55e; font-size: 1.1rem; }
.doc-missing { color: #ef4444; font-size: 1.1rem; }

.missing-docs {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #b45309;
  background: #fef3c7;
  border: 1px solid #fde68a;
  border-radius: 0.375rem;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
}

.fin-cards {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.fin-card {
  background: white;
  border-radius: 0.5rem;
  padding: 0.75rem 1.25rem;
  border: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 130px;
}

.fin-card.fin-ok     { border-color: #86efac; background: #f0fdf4; }
.fin-card.fin-warn   { border-color: #fcd34d; background: #fffbeb; }
.fin-card.fin-danger { border-color: #fca5a5; background: #fef2f2; }

.fin-label {
  font-size: 0.78rem;
  color: #6c757d;
  font-weight: 500;
  text-transform: uppercase;
}

.fin-value {
  font-size: 1.15rem;
  font-weight: 700;
  color: #2c3e50;
}

.fin-fees {
  margin-top: 0.5rem;
}

.no-data {
  color: #6c757d;
  font-style: italic;
  padding: 0.5rem 0;
  margin: 0;
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

  .form-grid {
    grid-template-columns: 1fr;
  }

  .field.col-span-2 {
    grid-column: span 1;
  }
}
</style>