<template>
  <div class="kitchen">
    <div class="container">
      <div class="header-section">
        <div class="header-info">
          <h2>👨‍🍳 Cozinha - Pedidos</h2>
          <div class="status-summary">
            <Badge :value="ordersByStatus.pending" severity="warning" />
            <span class="status-text">Pendentes</span>
            <Badge :value="ordersByStatus.preparing" severity="info" />
            <span class="status-text">Preparando</span>
            <Badge :value="ordersByStatus.ready" severity="success" />
            <span class="status-text">Prontos</span>
          </div>
        </div>
        <div class="header-actions">
          <Button
            label="Atualizar"
            icon="pi pi-refresh"
            class="p-button-outlined"
            @click="refreshOrders"
          />
          <Button
            label="Novo Pedido"
            icon="pi pi-plus"
            @click="$router.push('/orders')"
          />
        </div>
      </div>

      <!-- Filter Tabs -->
      <div class="filter-tabs">
        <Button
          :label="`Todos (${allOrders.length})`"
          :class="{ 'p-button-outlined': activeFilter !== 'all' }"
          @click="activeFilter = 'all'"
        />
        <Button
          :label="`Pendentes (${ordersByStatus.pending})`"
          :class="{ 'p-button-outlined': activeFilter !== 'pending' }"
          severity="warning"
          @click="activeFilter = 'pending'"
        />
        <Button
          :label="`Preparando (${ordersByStatus.preparing})`"
          :class="{ 'p-button-outlined': activeFilter !== 'preparing' }"
          severity="info"
          @click="activeFilter = 'preparing'"
        />
        <Button
          :label="`Prontos (${ordersByStatus.ready})`"
          :class="{ 'p-button-outlined': activeFilter !== 'ready' }"
          severity="success"
          @click="activeFilter = 'ready'"
        />
      </div>

      <!-- Orders Grid -->
      <div class="orders-grid">
        <div v-if="filteredOrders.length === 0" class="empty-state">
          <i class="pi pi-clock"></i>
          <h3>Nenhum pedido {{ getFilterText() }}</h3>
          <p>Os pedidos aparecerão aqui conforme forem sendo feitos.</p>
        </div>

        <div v-for="order in filteredOrders" :key="order.PK" class="order-card" :class="getOrderCardClass(order.Status)">
          <!-- Order Header -->
          <div class="order-header">
            <div class="order-info">
              <h4>Pedido #{{ order.PK }}</h4>
              <div class="order-meta">
                <span class="customer-name">{{ order.CustomerName }}</span>
                <span class="pathfinder-name">por {{ order.pathfinderName }}</span>
              </div>
            </div>
            <div class="order-actions">
              <Dropdown
                v-model="order.Status"
                :options="statusOptions"
                optionLabel="label"
                optionValue="value"
                @change="updateOrderStatus(order.PK, order.Status)"
                :class="getStatusClass(order.Status)"
              />
            </div>
          </div>

          <!-- Order Items -->
          <div class="order-items">
            <div v-for="item in order.itemsWithDetails" :key="`${item.ProductId}-${item.Flavor}`" class="order-item">
              <div class="item-badge">
                <Badge :value="item.Quantity" />
              </div>
              <div class="item-details">
                <div class="item-name">{{ item.productName }}</div>
                <div v-if="item.Flavor" class="item-flavor">{{ item.Flavor }}</div>
              </div>
              <div class="item-icons">
                <i :class="getProductIcon(item.ProductId)" :style="getProductIconColor(item.ProductId)"></i>
              </div>
            </div>
          </div>

          <!-- Order Footer -->
          <div class="order-footer">
            <div class="order-time">
              <i class="pi pi-clock"></i>
              <span>{{ formatTime(order.CreatedAt) }}</span>
            </div>
            <div class="order-total">
              <span class="total-label">Total:</span>
              <span class="total-amount">{{ formatCurrency(order.TotalAmount) }}</span>
            </div>
          </div>

          <!-- Order Notes -->
          <div v-if="order.Notes" class="order-notes">
            <i class="pi pi-info-circle"></i>
            <span>{{ order.Notes }}</span>
          </div>

          <!-- Quick Actions -->
          <div class="quick-actions">
            <Button
              v-if="order.Status === 'pending'"
              label="Iniciar Preparo"
              icon="pi pi-play"
              class="p-button-warning p-button-sm"
              @click="updateOrderStatus(order.PK, 'preparing')"
            />
            <Button
              v-if="order.Status === 'preparing'"
              label="Marcar Pronto"
              icon="pi pi-check"
              class="p-button-success p-button-sm"
              @click="updateOrderStatus(order.PK, 'ready')"
            />
            <Button
              v-if="order.Status === 'ready'"
              label="Marcar Entregue"
              icon="pi pi-check-circle"
              class="p-button-success p-button-sm"
              @click="updateOrderStatus(order.PK, 'delivered')"
            />
            <Button
              label="Ver Detalhes"
              icon="pi pi-eye"
              class="p-button-outlined p-button-sm"
              @click="showOrderDetails(order)"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Order Details Dialog -->
    <Dialog
      v-model:visible="showDetailsDialog"
      :header="`Detalhes do Pedido #${selectedOrder?.PK || ''}`"
      :modal="true"
      style="width: 600px"
    >
      <div v-if="selectedOrder" class="order-details">
        <!-- Customer Information -->
        <div class="details-section">
          <h6>Informações do Cliente</h6>
          <div class="details-grid">
            <div class="detail-item">
              <span class="label">Cliente:</span>
              <span class="value">{{ selectedOrder.CustomerName }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Desbravador:</span>
              <span class="value">{{ selectedOrder.pathfinderName }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Data do Pedido:</span>
              <span class="value">{{ formatDate(selectedOrder.Date) }}</span>
            </div>
            <div class="detail-item">
              <span class="label">Horário:</span>
              <span class="value">{{ formatTime(selectedOrder.CreatedAt) }}</span>
            </div>
          </div>
        </div>

        <!-- Items Details -->
        <div class="details-section">
          <h6>Itens do Pedido</h6>
          <div class="items-list">
            <div v-for="item in selectedOrder.itemsWithDetails" :key="`${item.ProductId}-${item.Flavor}`" class="item-detail">
              <div class="item-qty">{{ item.Quantity }}x</div>
              <div class="item-info">
                <div class="item-name">{{ item.productName }}</div>
                <div v-if="item.Flavor" class="item-flavor">{{ item.Flavor }}</div>
              </div>
              <div class="item-price">{{ formatCurrency(item.TotalPrice) }}</div>
            </div>
          </div>
        </div>

        <!-- Payment Information -->
        <div class="details-section">
          <h6>Informações de Pagamento</h6>
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
            <div class="payment-row">
              <span>Forma de Pagamento:</span>
              <span>{{ getPaymentMethodLabel(selectedOrder.PaymentMethod) }}</span>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="selectedOrder.Notes" class="details-section">
          <h6>Observações</h6>
          <div class="notes-content">
            {{ selectedOrder.Notes }}
          </div>
        </div>
      </div>

      <template #footer>
        <Button label="Fechar" icon="pi pi-times" @click="showDetailsDialog = false" />
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
const activeFilter = ref<'all' | 'pending' | 'preparing' | 'ready'>('all')
const showDetailsDialog = ref(false)
const selectedOrder = ref<any>(null)

// Computed properties
const allOrders = computed(() => fundraiserStore.kitchenOrders)
const ordersByStatus = computed(() => fundraiserStore.ordersByStatus)

const filteredOrders = computed(() => {
  if (activeFilter.value === 'all') {
    return allOrders.value
  }
  return allOrders.value.filter(order => order.Status === activeFilter.value)
})

const statusOptions = ref([
  { label: 'Pendente', value: 'pending' },
  { label: 'Preparando', value: 'preparing' },
  { label: 'Pronto', value: 'ready' },
  { label: 'Entregue', value: 'delivered' }
])

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

const formatTime = (dateString: string) => {
  return new Date(dateString).toLocaleTimeString('pt-BR', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getFilterText = () => {
  const texts = {
    all: 'encontrado',
    pending: 'pendente',
    preparing: 'em preparo',
    ready: 'pronto'
  }
  return texts[activeFilter.value]
}

const getOrderCardClass = (status: string) => {
  return {
    'order-pending': status === 'pending',
    'order-preparing': status === 'preparing',
    'order-ready': status === 'ready',
    'order-delivered': status === 'delivered'
  }
}

const getStatusClass = (status: string) => {
  return {
    'status-pending': status === 'pending',
    'status-preparing': status === 'preparing',
    'status-ready': status === 'ready',
    'status-delivered': status === 'delivered'
  }
}

const getProductIcon = (productId: string) => {
  const icons: Record<string, string> = {
    'PRODUCT#1': 'pi pi-circle-fill', // Pizza
    'PRODUCT#2': 'pi pi-stop-circle', // Pastel
    'PRODUCT#3': 'pi pi-heart-fill'   // Ice cream
  }
  return icons[productId] || 'pi pi-circle'
}

const getProductIconColor = (productId: string) => {
  const colors: Record<string, string> = {
    'PRODUCT#1': '#ff6b35', // Pizza - orange
    'PRODUCT#2': '#f7931e', // Pastel - yellow
    'PRODUCT#3': '#4ecdc4'  // Ice cream - cyan
  }
  return { color: colors[productId] || '#6c757d' }
}

const getPaymentMethodLabel = (method: string) => {
  const labels: Record<string, string> = {
    'card': 'Cartão',
    'cash': 'Dinheiro',
    'pix-church': 'Pix Igreja',
    'pix-qr': 'Pix QR Code'
  }
  return labels[method] || method
}

const updateOrderStatus = async (orderId: string, status: Order['Status']) => {
  try {
    await fundraiserStore.updateOrderStatus(orderId, status)

    const statusLabels: Record<string, string> = {
      'pending': 'pendente',
      'preparing': 'em preparo',
      'ready': 'pronto',
      'delivered': 'entregue'
    }

    toast.add({
      severity: 'success',
      summary: 'Status Atualizado',
      detail: `Pedido marcado como ${statusLabels[status]}`,
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao atualizar status do pedido',
      life: 3000
    })
  }
}

const showOrderDetails = (order: any) => {
  selectedOrder.value = order
  showDetailsDialog.value = true
}

const refreshOrders = async () => {
  // In a real app, this would fetch from the server
  await fundraiserStore.loadFromSupabase()
  toast.add({
    severity: 'info',
    summary: 'Atualizado',
    detail: 'Lista de pedidos atualizada',
    life: 2000
  })
}

onMounted(() => {
  // Auto-refresh every 30 seconds in a real implementation
  // setInterval(refreshOrders, 30000)
})
</script>

<style scoped>
.kitchen {
  min-height: 100vh;
  background: #f8f9fa;
  overflow-x: hidden;
}

.container {
  width: 100%;
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

.header-info h2 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
  font-size: 2rem;
}

.status-summary {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.status-text {
  font-size: 0.875rem;
  color: #6c757d;
  margin-right: 1rem;
}

.header-actions {
  display: flex;
  gap: 1rem;
}

.filter-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.orders-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

@media (max-width: 1024px) {
  .orders-grid {
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 1rem;
  }
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 4rem 2rem;
  color: #6c757d;
}

.empty-state i {
  font-size: 4rem;
  margin-bottom: 1rem;
  display: block;
}

.empty-state h3 {
  margin: 0 0 0.5rem 0;
  color: #495057;
}

.order-card {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 2px solid transparent;
  transition: all 0.2s ease;
}

.order-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.order-card.order-pending {
  border-color: #ffc107;
  background: linear-gradient(135deg, #fff9e6 0%, #ffffff 100%);
}

.order-card.order-preparing {
  border-color: #17a2b8;
  background: linear-gradient(135deg, #e6f8ff 0%, #ffffff 100%);
}

.order-card.order-ready {
  border-color: #28a745;
  background: linear-gradient(135deg, #e8f5e8 0%, #ffffff 100%);
}

.order-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.order-info h4 {
  margin: 0 0 0.25rem 0;
  color: #2c3e50;
  font-size: 1.125rem;
  font-weight: 600;
}

.order-meta {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.customer-name {
  font-weight: 500;
  color: #495057;
}

.pathfinder-name {
  font-size: 0.875rem;
  color: #6c757d;
}

.order-items {
  margin-bottom: 1rem;
}

.order-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f8f9fa;
}

.order-item:last-child {
  border-bottom: none;
}

.item-badge {
  flex-shrink: 0;
}

.item-details {
  flex: 1;
}

.item-name {
  font-weight: 500;
  color: #2c3e50;
  font-family: monospace;
  white-space: pre;
}

.item-flavor {
  font-size: 0.875rem;
  color: #6c757d;
  margin-left: 2rem;
}

.item-icons {
  flex-shrink: 0;
  font-size: 1.25rem;
}

.order-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #f8f9fa;
}

.order-time {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #6c757d;
  font-size: 0.875rem;
}

.order-total {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.total-label {
  color: #6c757d;
  font-size: 0.875rem;
}

.total-amount {
  font-weight: bold;
  color: #2c3e50;
  font-size: 1.125rem;
}

.order-notes {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.75rem;
  background: #e3f2fd;
  border-radius: 0.5rem;
  margin-bottom: 1rem;
  font-size: 0.875rem;
  color: #1976d2;
}

.quick-actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.quick-actions .p-button {
  flex: 1;
  min-width: 120px;
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

.status-pending :deep(.p-dropdown) {
  background: #fff3cd;
  border-color: #ffc107;
}

.status-preparing :deep(.p-dropdown) {
  background: #d1ecf1;
  border-color: #17a2b8;
}

.status-ready :deep(.p-dropdown) {
  background: #d4edda;
  border-color: #28a745;
}

.status-delivered :deep(.p-dropdown) {
  background: #e2e3e5;
  border-color: #6c757d;
}

@media (max-width: 768px) {
  .container {
    padding: 0.5rem;
  }

  .header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .header-info h2 {
    font-size: 1.5rem;
  }

  .status-summary {
    flex-wrap: wrap;
    gap: 0.5rem;
  }

  .header-actions {
    width: 100%;
    justify-content: flex-start;
    gap: 0.75rem;
  }

  .filter-tabs {
    overflow-x: auto;
    padding-bottom: 0.5rem;
    gap: 0.25rem;
  }

  .orders-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .order-card {
    padding: 1rem;
  }

  .details-grid {
    grid-template-columns: 1fr;
  }

  .quick-actions {
    flex-direction: column;
  }

  .quick-actions .p-button {
    width: 100%;
    min-width: unset;
  }
}

@media (max-width: 480px) {
  .container {
    padding: 0.25rem;
  }

  .order-card {
    padding: 0.75rem;
  }

  .header-info h2 {
    font-size: 1.25rem;
  }

  .order-header {
    flex-direction: column;
    gap: 0.75rem;
  }

  .order-actions {
    width: 100%;
  }

  .filter-tabs {
    flex-direction: column;
    overflow-x: visible;
  }

  .empty-state {
    padding: 2rem 1rem;
  }

  .empty-state i {
    font-size: 3rem;
  }
}
</style>