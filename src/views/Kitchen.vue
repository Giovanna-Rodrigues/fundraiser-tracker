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
const completedItems = ref<Record<string, Record<string, boolean>>>({})

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
const getOrderNumber = (order: any) => {
  // Create a short order number from the creation timestamp
  const date = new Date(order.CreatedAt)
  const timeNumber = date.getHours().toString().padStart(2, '0') +
                   date.getMinutes().toString().padStart(2, '0')
  const dayOfYear = Math.floor((date.getTime() - new Date(date.getFullYear(), 0, 0).getTime()) / 1000 / 60 / 60 / 24)
  return `${dayOfYear.toString().padStart(3, '0')}-${timeNumber}`
}

const getOrderStatus = (orderId: string) => {
  // Always get the latest status from the store
  const storeOrder = fundraiserStore.orders.find(o => o.PK === orderId)
  return storeOrder?.Status || 'pending'
}

const getItemId = (item: any) => {
  return `${item.ProductId}-${item.Flavor || 'no-flavor'}`
}

const isItemCompleted = (orderId: string, item: any) => {
  if (!completedItems.value[orderId]) return false
  const itemId = getItemId(item)
  return completedItems.value[orderId][itemId] || false
}

const toggleItemCompletion = (orderId: string, item: any) => {

  if (!completedItems.value[orderId]) {
    completedItems.value[orderId] = {}
  }

  const itemId = getItemId(item)
  const isCompleted = !isItemCompleted(orderId, item)
  completedItems.value[orderId][itemId] = isCompleted

  // Find the order to get all items
  const order = allOrders.value.find(o => o.PK === orderId)
  if (!order) return

  // Handle combo logic
  if (item.productName.includes('▼')) {
    // This is a combo header - toggle all its sub-items
    const comboProductId = item.ProductId
    order.itemsWithDetails.forEach((orderItem: any) => {
      if (orderItem.productName.startsWith('  └─') &&
          orderItem.ProductId !== comboProductId) {
        // This is a sub-item, find its parent combo
        const comboItem = order.itemsWithDetails.find((ci: any) =>
          ci.ProductId === comboProductId && ci.productName.includes('▼')
        )
        if (comboItem) {
          completedItems.value[orderId][getItemId(orderItem)] = isCompleted
        }
      }
    })
  } else if (item.productName.startsWith('  └─')) {
    // This is a sub-item - find its specific parent combo and check only those sub-items
    // Find the combo that this sub-item belongs to by looking backwards in the array
    let comboItem = null
    const items = order.itemsWithDetails
    const currentIndex = items.findIndex(oi => oi === item)

    // Look backwards from current item to find the combo header
    for (let i = currentIndex - 1; i >= 0; i--) {
      if (items[i].productName.includes('▼')) {
        comboItem = items[i]
        break
      }
      // If we hit another regular item (not sub-item), this sub-item is orphaned
      if (!items[i].productName.startsWith('  └─')) {
        break
      }
    }

    if (comboItem) {
      // Get only the sub-items that belong to this specific combo
      // Start from combo position and collect sub-items until we hit non-sub-item
      const comboIndex = items.findIndex(oi => oi === comboItem)
      const subItems = []

      for (let i = comboIndex + 1; i < items.length && items[i].productName.startsWith('  └─'); i++) {
        subItems.push(items[i])
      }

      const allSubItemsCompleted = subItems.every((subItem: any) => {
        // Check the current state directly from completedItems to avoid stale reads
        const itemId = getItemId(subItem)
        return completedItems.value[orderId]?.[itemId] || false
      })

      // Update combo status based on sub-items
      completedItems.value[orderId][getItemId(comboItem)] = allSubItemsCompleted
    }
  }

  // Update order status based on item completion
  updateOrderStatusBasedOnItems(orderId)

  toast.add({
    severity: isCompleted ? 'success' : 'info',
    summary: isCompleted ? 'Item Pronto' : 'Item Pendente',
    detail: `${item.productName.replace('▼', '').replace('  └─ ', '')} ${isCompleted ? 'marcado como pronto' : 'desmarcado'}`,
    life: 2000
  })
}

const getItemCompletionCount = (orderId: string) => {
  const order = allOrders.value.find(o => o.PK === orderId)
  if (!order) return { completed: 0, total: 0 }

  // Count all items INCLUDING sub-items individually for progress tracking
  const allItems = order.itemsWithDetails
  let completed = 0
  let total = 0

  // Process each item individually
  for (let i = 0; i < allItems.length; i++) {
    const item = allItems[i]

    if (item.productName.includes('▼')) {
      // This is a combo header - don't count it, only the sub-items matter
    } else if (item.productName.startsWith('  └─')) {
      // This is a sub-item - count it individually
      total += 1
      const itemId = getItemId(item)
      const itemCompleted = completedItems.value[orderId]?.[itemId] || false
      if (itemCompleted) {
        completed += 1
      }
    } else {
      // This is a regular item (not a combo, not a sub-item)
      total += 1
      const itemId = getItemId(item)
      const itemCompleted = completedItems.value[orderId]?.[itemId] || false
      if (itemCompleted) {
        completed += 1
      }
    }
  }

  return { completed, total }
}

const updateOrderStatusBasedOnItems = async (orderId: string) => {
  const order = allOrders.value.find(o => o.PK === orderId)
  if (!order) return

  const { completed, total } = getItemCompletionCount(orderId)

  // Determine new status based solely on item completion
  let newStatus: Order['Status']

  if (completed === 0) {
    // No items completed - set to pending
    newStatus = 'pending'
  } else if (completed === total) {
    // All items completed - set to ready
    newStatus = 'ready'
  } else if (completed > 0 && completed < total) {
    // Some items completed - set to preparing
    newStatus = 'preparing'
  } else {
    // Fallback to current status (shouldn't happen)
    newStatus = order.Status
  }

  // Only update if status changed
  if (newStatus !== order.Status) {
    try {
      await fundraiserStore.updateOrderStatus(orderId, newStatus)

      const statusLabels: Record<string, string> = {
        'pending': 'pendente',
        'preparing': 'em preparo',
        'ready': 'pronto'
      }
    } catch (error) {
      console.error('Error updating order status:', error)
    }
  }
}

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
  setInterval(refreshOrders, 300000) // Refresh every 5 minutes
})
</script>

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

        <div v-for="order in filteredOrders" :key="order.PK" class="order-card" :class="getOrderCardClass(getOrderStatus(order.PK))">
          <!-- Order Header -->
          <div class="order-header">
            <div class="order-info">
              <h4>Pedido #{{ getOrderNumber(order) }}</h4>
              <div class="order-meta">
                <span class="customer-name">{{ order.CustomerName }}</span>
                <span class="pathfinder-name">por {{ order.pathfinderName }}</span>
              </div>
            </div>
            <div class="order-actions">
              <Dropdown
                :model-value="getOrderStatus(order.PK)"
                :options="statusOptions"
                optionLabel="label"
                optionValue="value"
                @update:model-value="updateOrderStatus(order.PK, $event)"
                :class="getStatusClass(getOrderStatus(order.PK))"
              />
            </div>
          </div>

          <!-- Order Items -->
          <div class="order-items">
            <div v-for="item in order.itemsWithDetails" :key="`${item.ProductId}-${item.Flavor}`"
                 class="order-item"
                 :class="{ 'item-completed': isItemCompleted(order.PK, item) }">
              <div class="item-badge"
                   :class="{ 'badge-clickable': true, 'badge-completed': isItemCompleted(order.PK, item) }"
                   @click="toggleItemCompletion(order.PK, item)"
                   :title="isItemCompleted(order.PK, item) ? 'Clique para marcar como pendente' : 'Clique para marcar como pronto'">
                <Badge :value="item.Quantity" />
                <i v-if="isItemCompleted(order.PK, item)" class="pi pi-check completion-check"></i>
              </div>
              <div class="item-details">
                <div class="item-name" :class="{ 'completed-text': isItemCompleted(order.PK, item) }">{{ item.productName }}</div>
                <div v-if="item.Flavor" class="item-flavor" :class="{ 'completed-text': isItemCompleted(order.PK, item) }">{{ item.Flavor }}</div>
              </div>
            </div>

            <!-- Progress indicator -->
            <div class="order-progress">
              <div class="progress-text">
                {{ getItemCompletionCount(order.PK).completed }} / {{ getItemCompletionCount(order.PK).total }} itens prontos
              </div>
              <div class="progress-bar">
                <div class="progress-fill"
                     :style="{ width: (getItemCompletionCount(order.PK).completed / getItemCompletionCount(order.PK).total * 100) + '%' }"></div>
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
      :header="`Detalhes do Pedido #${selectedOrder ? getOrderNumber(selectedOrder) : ''}`"
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

.order-actions {
  flex-shrink: 0;
  min-width: 140px;
}

.order-actions :deep(.p-dropdown) {
  width: 140px;
  font-size: 0.875rem;
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

.badge-clickable {
  position: relative;
  cursor: pointer;
  transition: all 0.2s ease;
  border-radius: 50%;
  padding: 2px;
}

.badge-clickable:hover {
  transform: scale(1.1);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.badge-completed {
  background: #28a745;
  color: white;
  border-radius: 50%;
}

.completion-check {
  position: absolute;
  top: -2px;
  right: -2px;
  background: #28a745;
  color: white;
  border-radius: 50%;
  font-size: 0.75rem;
  width: 16px;
  height: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.item-completed {
  opacity: 0.7;
}

.completed-text {
  text-decoration: line-through;
  color: #6c757d;
}

.order-progress {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #f8f9fa;
}

.progress-text {
  font-size: 0.875rem;
  color: #6c757d;
  margin-bottom: 0.5rem;
  text-align: center;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: #e9ecef;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #28a745, #20c997);
  border-radius: 3px;
  transition: width 0.3s ease;
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