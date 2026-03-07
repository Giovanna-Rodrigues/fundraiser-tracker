<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { Order } from '@/stores/fundraiser'

// Store and utilities
const fundraiserStore = useFundraiserStore()
const toast = useToast()

// Component state
const showOrderDetails = ref(false)
const selectedOrder = ref<Order | null>(null)
const showPaymentDialog = ref(false)
const paymentOrder = ref<Order | null>(null)
const selectedPaymentMethod = ref<string | null>(null)

const paymentMethodOptions = [
  { label: 'Cartão', value: 'card' },
  { label: 'Dinheiro', value: 'cash' },
  { label: 'Pix Igreja', value: 'pix-church' },
  { label: 'Pix QR', value: 'pix-qr' }
]

// Filters
const filters = ref({
  dateFrom: null as Date | null,
  dateTo: null as Date | null,
  PathfinderId: null as string | null,
  Status: null as string | null
})

// Computed properties
const pathfinderFilterOptions = computed(() => [
  { label: 'Todos os desbravadores', value: null },
  ...fundraiserStore.pathfinders.map(pathfinder => ({
    label: pathfinder.Name,
    value: pathfinder.PK
  }))
])

const statusFilterOptions = ref([
  { label: 'Todos os status', value: null },
  { label: 'Pendente', value: 'pending' },
  { label: 'Preparando', value: 'preparing' },
  { label: 'Pronto', value: 'ready' },
  { label: 'Entregue', value: 'delivered' },
  { label: 'Não Retirado', value: 'not_picked_up' }
])

const filteredOrders = computed(() => {
  let orders = fundraiserStore.ordersWithDetails

  // Filter by date range
  if (filters.value.dateFrom) {
    const fromDate = new Date(filters.value.dateFrom).toISOString().split('T')[0]
    orders = orders.filter((order: any) => order.Date >= fromDate)
  }

  if (filters.value.dateTo) {
    const toDate = new Date(filters.value.dateTo).toISOString().split('T')[0]
    orders = orders.filter((order: any) => order.Date <= toDate)
  }

  // Filter by pathfinder
  if (filters.value.PathfinderId) {
    orders = orders.filter((order: any) => order.PathfinderId === filters.value.PathfinderId)
  }

  // Filter by status
  if (filters.value.Status) {
    orders = orders.filter((order: any) => order.Status === filters.value.Status)
  }

  return orders
})

const totalFilteredSales = computed(() => {
  return filteredOrders.value.reduce((sum: number, order: any) => sum + order.TotalAmount, 0)
})

const totalFilteredItems = computed(() => {
  return filteredOrders.value.reduce((sum: number, order: any) => {
    return sum + order.items.reduce((itemSum: number, item: any) => itemSum + item.Quantity, 0)
  }, 0)
})

// Methods
const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value || 0)
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('pt-BR')
}

const getPaymentMethodLabel = (method: string | null | undefined) => {
  if (!method) return 'Pagar depois'
  const labels: Record<string, string> = {
    card: 'Cartão',
    cash: 'Dinheiro',
    'pix-church': 'Pix Igreja',
    'pix-qr': 'Pix QR'
  }
  return labels[method] || method
}

const getPaymentMethodSeverity = (method: string | null | undefined) => {
  if (!method) return 'warn'
  const severities: Record<string, string> = {
    card: 'info',
    cash: 'success',
    'pix-church': 'warn',
    'pix-qr': 'warn'
  }
  return severities[method] || 'secondary'
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    pending: 'Pendente',
    preparing: 'Preparando',
    ready: 'Pronto',
    delivered: 'Entregue',
    not_picked_up: 'Não Retirado'
  }
  return labels[status] || status
}

const getStatusSeverity = (status: string) => {
  const severities: Record<string, string> = {
    pending: 'warn',
    preparing: 'info',
    ready: 'success',
    delivered: 'secondary',
    not_picked_up: 'danger'
  }
  return severities[status] || 'secondary'
}

const applyFilters = () => {
  // Filters are applied automatically via computed property
}

const clearFilters = () => {
  filters.value = {
    dateFrom: null,
    dateTo: null,
    PathfinderId: null,
    Status: null
  }
}

const viewOrderDetails = (order: Order) => {
  selectedOrder.value = order
  showOrderDetails.value = true
}

const openPaymentDialog = (order: Order) => {
  paymentOrder.value = order
  selectedPaymentMethod.value = null
  showPaymentDialog.value = true
}

const confirmPayment = async () => {
  if (!paymentOrder.value || !selectedPaymentMethod.value) return
  try {
    await fundraiserStore.updateOrder(paymentOrder.value.PK, {
      PaymentMethod: selectedPaymentMethod.value as any
    })
    toast.add({ severity: 'success', summary: 'Pagamento registrado', life: 3000 })
    showPaymentDialog.value = false
  } catch {
    toast.add({ severity: 'error', summary: 'Erro ao registrar pagamento', life: 3000 })
  }
}

const markNotPickedUp = async (order: Order) => {
  try {
    await fundraiserStore.updateOrderStatus(order.PK, 'not_picked_up')
    toast.add({ severity: 'info', summary: 'Pedido marcado como não retirado', life: 3000 })
  } catch {
    toast.add({ severity: 'error', summary: 'Erro ao atualizar pedido', life: 3000 })
  }
}

const exportData = () => {
  try {
    fundraiserStore.exportToCSV()
    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Relatório exportado com sucesso!',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao exportar relatório',
      life: 3000
    })
  }
}
</script>

<template>
  <div class="sales-list">
    <div class="container">
      <div class="header-section">
        <h2>📋 Histórico de Vendas</h2>
        <div class="header-actions">
          <Button
            label="Voltar ao Dashboard"
            icon="pi pi-arrow-left"
            class="p-button-outlined"
            @click="$router.push('/')"
          />
          <Button
            label="Exportar Relatório"
            icon="pi pi-download"
            @click="exportData"
          />
        </div>
      </div>

      <!-- Filters -->
      <div class="filters-section">
        <div class="filters-card">
          <h3>Filtros</h3>
          <div class="filters-grid">
            <div class="field">
              <label for="dateFrom">Data Inicial</label>
              <Calendar
                id="dateFrom"
                v-model="filters.dateFrom"
                dateFormat="dd/mm/yy"
                placeholder="Selecione a data inicial"
                @update:modelValue="applyFilters"
              />
            </div>

            <div class="field">
              <label for="dateTo">Data Final</label>
              <Calendar
                id="dateTo"
                v-model="filters.dateTo"
                dateFormat="dd/mm/yy"
                placeholder="Selecione a data final"
                @update:modelValue="applyFilters"
              />
            </div>

            <div class="field">
              <label for="pathfinderFilter">Desbravador</label>
              <Dropdown
                id="pathfinderFilter"
                v-model="filters.PathfinderId"
                :options="pathfinderFilterOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="Todos os desbravadores"
                @update:modelValue="applyFilters"
              />
            </div>

            <div class="field">
              <label for="statusFilter">Status</label>
              <Dropdown
                id="statusFilter"
                v-model="filters.Status"
                :options="statusFilterOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="Todos os status"
                @update:modelValue="applyFilters"
              />
            </div>
          </div>

          <div class="filter-actions">
            <Button
              label="Limpar Filtros"
              icon="pi pi-times"
              class="p-button-outlined p-button-secondary"
              @click="clearFilters"
            />
          </div>
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="summary-section">
        <div class="summary-card">
          <div class="summary-content">
            <span class="summary-label">Total de Pedidos</span>
            <span class="summary-value">{{ filteredOrders.length }}</span>
          </div>
        </div>

        <div class="summary-card">
          <div class="summary-content">
            <span class="summary-label">Valor Total</span>
            <span class="summary-value">{{ formatCurrency(totalFilteredSales) }}</span>
          </div>
        </div>

        <div class="summary-card">
          <div class="summary-content">
            <span class="summary-label">Produtos Vendidos</span>
            <span class="summary-value">{{ totalFilteredItems }}</span>
          </div>
        </div>
      </div>

      <!-- Sales Table -->
      <div class="table-section">
        <DataTable
          :value="filteredOrders"
          :paginator="true"
          :rows="20"
          :rowsPerPageOptions="[10, 20, 50]"
          sortField="CreatedAt"
          :sortOrder="-1"
          class="p-datatable-sm"
          stripedRows
          responsiveLayout="scroll"
        >
          <Column field="PK" header="Pedido #" sortable style="width: 100px">
            <template #body="{ data }">
              <strong>#{{ data.PK }}</strong>
            </template>
          </Column>

          <Column field="Date" header="Data" sortable style="width: 120px">
            <template #body="{ data }">
              {{ formatDate(data.Date) }}
            </template>
          </Column>

          <Column field="CustomerName" header="Cliente" sortable>
            <template #body="{ data }">
              <div class="customer-info">
                <strong>{{ data.CustomerName }}</strong>
                <small>por {{ (data as any).pathfinderName }}</small>
              </div>
            </template>
          </Column>

          <Column header="Itens" style="min-width: 200px">
            <template #body="{ data }">
              <div class="items-summary">
                <div v-for="item in (data as any).itemsWithDetails" :key="`${item.ProductId}-${item.Flavor}`" class="item-line">
                  <Badge :value="item.Quantity" class="item-qty" />
                  <span class="item-name">{{ item.productName }}</span>
                  <span v-if="item.Flavor" class="item-flavor">({{ item.Flavor }})</span>
                </div>
              </div>
            </template>
          </Column>

          <Column field="PaymentMethod" header="Pagamento" sortable style="width: 120px">
            <template #body="{ data }">
              <Tag
                :value="getPaymentMethodLabel(data.PaymentMethod)"
                :severity="getPaymentMethodSeverity(data.PaymentMethod)"
              />
            </template>
          </Column>

          <Column field="Status" header="Status" sortable style="width: 120px">
            <template #body="{ data }">
              <Tag
                :value="getStatusLabel(data.Status)"
                :severity="getStatusSeverity(data.Status)"
              />
            </template>
          </Column>

          <Column field="TotalAmount" header="Total" sortable style="width: 120px">
            <template #body="{ data }">
              <strong>{{ formatCurrency(data.TotalAmount) }}</strong>
            </template>
          </Column>

          <Column header="Ações" style="width: 180px">
            <template #body="{ data }">
              <div class="row-actions">
                <Button
                  icon="pi pi-eye"
                  class="p-button-outlined p-button-sm"
                  @click="viewOrderDetails(data)"
                  v-tooltip.top="'Ver detalhes'"
                />
                <Button
                  v-if="!data.PaymentMethod"
                  icon="pi pi-credit-card"
                  class="p-button-sm p-button-warning"
                  @click="openPaymentDialog(data)"
                  v-tooltip.top="'Registrar pagamento'"
                />
                <Button
                  v-if="data.Status !== 'delivered' && data.Status !== 'not_picked_up'"
                  icon="pi pi-ban"
                  class="p-button-sm p-button-danger p-button-outlined"
                  @click="markNotPickedUp(data)"
                  v-tooltip.top="'Marcar como não retirado'"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Order Details Dialog -->
    <Dialog
      v-model:visible="showOrderDetails"
      header="Detalhes do Pedido"
      :modal="true"
      style="width: 600px"
    >
      <div v-if="selectedOrder" class="order-details">
        <div class="details-section">
          <h6>Informações Gerais</h6>
          <div class="details-grid">
            <div class="detail-item">
              <span class="label">Pedido:</span>
              <span class="value">#{{ selectedOrder.PK }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Data:</span>
              <span class="value">{{ formatDate(selectedOrder.Date) }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Cliente:</span>
              <span class="value">{{ selectedOrder.CustomerName }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Desbravador:</span>
              <span class="value">{{ (selectedOrder as any)?.pathfinderName }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Status:</span>
              <Tag
                :value="getStatusLabel(selectedOrder.Status)"
                :severity="getStatusSeverity(selectedOrder.Status)"
              />
            </div>
            <div class="detail-item">
              <span class="label">Pagamento:</span>
              <Tag
                :value="getPaymentMethodLabel(selectedOrder.PaymentMethod)"
                :severity="getPaymentMethodSeverity(selectedOrder.PaymentMethod)"
              />
            </div>
          </div>
        </div>

        <div class="details-section">
          <h6>Itens do Pedido</h6>
          <div class="items-list">
            <div v-for="item in (selectedOrder as any)?.itemsWithDetails" :key="`${item.ProductId}-${item.Flavor}`" class="item-detail">
              <div class="item-qty">{{ item.Quantity }}x</div>
              <div class="item-info">
                <div class="item-name">{{ item.productName }}</div>
                <div v-if="item.Flavor" class="item-flavor">{{ item.Flavor }}</div>
              </div>
              <div class="item-price">{{ formatCurrency(item.TotalPrice) }}</div>
            </div>
          </div>
        </div>

        <div class="details-section">
          <h6>Resumo Financeiro</h6>
          <div class="payment-details">
            <div class="payment-row">
              <span>Subtotal:</span>
              <span>{{ formatCurrency(selectedOrder.Subtotal) }}</span>
            </div>
            <div v-if="selectedOrder.Discount > 0" class="payment-row">
              <span>Desconto:</span>
              <span class="discount">-{{ formatCurrency(selectedOrder.Discount) }}</span>
            </div>
            <div class="payment-row total">
              <span>Total:</span>
              <span>{{ formatCurrency(selectedOrder.TotalAmount) }}</span>
            </div>
          </div>
        </div>

        <div v-if="selectedOrder.Notes" class="details-section">
          <h6>Observações</h6>
          <div class="notes-content">
            {{ selectedOrder.Notes }}
          </div>
        </div>
      </div>

      <template #footer>
        <Button
          label="Fechar"
          icon="pi pi-times"
          class="p-button-text"
          @click="showOrderDetails = false"
        />
      </template>
    </Dialog>

    <!-- Payment Registration Dialog -->
    <Dialog
      v-model:visible="showPaymentDialog"
      header="Registrar Pagamento"
      :modal="true"
      style="width: 400px"
    >
      <div v-if="paymentOrder" class="payment-dialog-content">
        <p>Pedido <strong>#{{ paymentOrder.PK }}</strong> — {{ paymentOrder.CustomerName }}</p>
        <p class="payment-amount">Total: <strong>{{ formatCurrency(paymentOrder.TotalAmount) }}</strong></p>

        <div class="field">
          <label>Forma de pagamento</label>
          <Dropdown
            v-model="selectedPaymentMethod"
            :options="paymentMethodOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Selecione a forma de pagamento"
          />
        </div>
      </div>

      <template #footer>
        <Button
          label="Cancelar"
          icon="pi pi-times"
          class="p-button-text"
          @click="showPaymentDialog = false"
        />
        <Button
          label="Confirmar"
          icon="pi pi-check"
          :disabled="!selectedPaymentMethod"
          @click="confirmPayment"
        />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<style scoped>
.sales-list {
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

.filters-section {
  margin-bottom: 2rem;
}

.filters-card {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.filters-card h3 {
  margin: 0 0 1.5rem 0;
  color: #2c3e50;
  font-size: 1.25rem;
}

.filters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.field label {
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
  font-size: 0.875rem;
}

.filter-actions {
  display: flex;
  justify-content: flex-end;
}

.summary-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.summary-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.summary-content {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.summary-label {
  color: #6c757d;
  font-size: 0.875rem;
  font-weight: 500;
}

.summary-value {
  color: #2c3e50;
  font-size: 1.5rem;
  font-weight: bold;
}

.table-section {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.customer-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.customer-info small {
  color: #6c757d;
  font-size: 0.8rem;
}

.items-summary {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.item-line {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.item-qty {
  flex-shrink: 0;
}

.item-name {
  font-weight: 500;
}

.item-flavor {
  color: #6c757d;
  font-size: 0.875rem;
}

.order-details {
  padding: 1rem 0;
}

.details-section {
  margin-bottom: 2rem;
}

.details-section h6 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
  font-size: 1rem;
  font-weight: 600;
}

.details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.detail-item .label {
  font-size: 0.875rem;
  color: #6c757d;
  font-weight: 500;
}

.detail-item .value {
  color: #2c3e50;
}

.items-list {
  border: 1px solid #e9ecef;
  border-radius: 0.5rem;
  overflow: hidden;
}

.item-detail {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-bottom: 1px solid #e9ecef;
}

.item-detail:last-child {
  border-bottom: none;
}

.item-qty {
  font-weight: bold;
  color: #2c3e50;
  min-width: 40px;
}

.item-info {
  flex: 1;
}

.item-info .item-name {
  font-weight: 500;
  color: #2c3e50;
}

.item-info .item-flavor {
  font-size: 0.875rem;
  color: #6c757d;
}

.item-price {
  font-weight: 500;
  color: #2c3e50;
}

.payment-details {
  border: 1px solid #e9ecef;
  border-radius: 0.5rem;
  padding: 1rem;
}

.payment-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f8f9fa;
}

.payment-row:last-child {
  border-bottom: none;
}

.payment-row.total {
  font-weight: bold;
  font-size: 1.125rem;
  border-top: 1px solid #e9ecef;
  margin-top: 0.5rem;
  padding-top: 1rem;
}

.payment-row .discount {
  color: #dc3545;
}

.notes-content {
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 0.5rem;
  color: #495057;
}

.row-actions {
  display: flex;
  gap: 0.4rem;
  align-items: center;
}

.payment-dialog-content {
  padding: 0.5rem 0;
}

.payment-dialog-content .field {
  margin-top: 1rem;
}

.payment-amount {
  color: #2c3e50;
  font-size: 1rem;
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

  .filters-grid {
    grid-template-columns: 1fr;
  }

  .summary-section {
    grid-template-columns: 1fr;
  }

  .details-grid {
    grid-template-columns: 1fr;
  }

  .container {
    padding: 0.5rem;
  }
}
</style>