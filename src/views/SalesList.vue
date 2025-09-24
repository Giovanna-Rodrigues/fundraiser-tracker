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

          <Column header="Ações" style="width: 100px">
            <template #body="{ data }">
              <Button
                icon="pi pi-eye"
                class="p-button-outlined p-button-sm"
                @click="viewOrderDetails(data)"
                v-tooltip.top="'Ver detalhes'"
              />
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

    <Toast />
  </div>
</template>

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
  { label: 'Entregue', value: 'delivered' }
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

const getPaymentMethodLabel = (method: string) => {
  const labels: Record<string, string> = {
    card: 'Cartão',
    cash: 'Dinheiro',
    'pix-church': 'Pix Igreja',
    'pix-qr': 'Pix QR'
  }
  return labels[method] || method
}

const getPaymentMethodSeverity = (method: string) => {
  const severities: Record<string, string> = {
    card: 'info',
    cash: 'success',
    'pix-church': 'warning',
    'pix-qr': 'warning'
  }
  return severities[method] || 'secondary'
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    pending: 'Pendente',
    preparing: 'Preparando',
    ready: 'Pronto',
    delivered: 'Entregue'
  }
  return labels[status] || status
}

const getStatusSeverity = (status: string) => {
  const severities: Record<string, string> = {
    pending: 'warning',
    preparing: 'info',
    ready: 'success',
    delivered: 'secondary'
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

onMounted(() => {
  // Component is ready
})
</script>

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