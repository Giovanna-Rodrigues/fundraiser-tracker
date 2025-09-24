<template>
  <div class="order-entry">
    <div class="container">
      <div class="header-section">
        <h2>📝 Novo Pedido</h2>
        <Button
          label="Voltar ao Dashboard"
          icon="pi pi-arrow-left"
          class="p-button-outlined"
          @click="$router.push('/')"
        />
      </div>

      <div class="order-form">
        <div class="form-section">
          <!-- Customer Info -->
          <div class="info-card">
            <h3>Informações do Cliente</h3>
            <div class="form-grid">
              <div class="field">
                <label for="pathfinder">Desbravador *</label>
                <Dropdown
                  id="pathfinder"
                  v-model="orderForm.PathfinderId"
                  :options="pathfinderOptions"
                  optionLabel="label"
                  optionValue="value"
                  placeholder="Selecione um desbravador"
                  :class="{ 'p-invalid': submitted && !orderForm.PathfinderId }"
                  :filter="true"
                  filterBy="label"
                />
                <small v-if="submitted && !orderForm.PathfinderId" class="p-error">
                  Desbravador é obrigatório.
                </small>
              </div>

              <div class="field">
                <label for="customerName">Nome do Cliente *</label>
                <InputText
                  id="customerName"
                  v-model="orderForm.CustomerName"
                  placeholder="Nome de quem vai retirar o pedido"
                  :class="{ 'p-invalid': submitted && !orderForm.CustomerName }"
                />
                <small v-if="submitted && !orderForm.CustomerName" class="p-error">
                  Nome do cliente é obrigatório.
                </small>
              </div>

              <div class="field">
                <label for="date">Data do Pedido *</label>
                <Calendar
                  id="date"
                  v-model="orderForm.Date"
                  dateFormat="dd/mm/yy"
                  :class="{ 'p-invalid': submitted && !orderForm.Date }"
                />
              </div>
            </div>
          </div>

          <!-- Order Items -->
          <div class="items-card">
            <div class="items-header">
              <h3>Itens do Pedido</h3>
              <Button
                label="Adicionar Item"
                icon="pi pi-plus"
                class="p-button-success p-button-sm"
                @click="addItem"
              />
            </div>

            <div v-if="orderForm.items.length === 0" class="empty-items">
              <i class="pi pi-shopping-cart"></i>
              <p>Nenhum item adicionado. Clique em "Adicionar Item" para começar.</p>
            </div>

            <div v-for="(item, index) in orderForm.items" :key="index" class="item-row">
              <div class="item-header">
                <div class="item-number">
                  <i class="pi pi-shopping-cart"></i>
                  <span>Item {{ index + 1 }}</span>
                </div>
                <Button
                  icon="pi pi-trash"
                  class="p-button-danger p-button-text p-button-sm remove-btn"
                  @click="removeItem(index)"
                  :disabled="orderForm.items.length <= 1"
                />
              </div>

              <div class="item-grid">
                <div class="field">
                  <label>Produto *</label>
                  <Dropdown
                    v-model="item.ProductId"
                    :options="productOptions"
                    optionLabel="label"
                    optionValue="value"
                    placeholder="Selecione um produto"
                    @update:modelValue="updateItemProduct(index)"
                  />
                </div>

                <!-- Regular Product Flavor Selection -->
                <div class="field" v-if="!isComboProduct(item.ProductId) && getProductFlavors(item.ProductId).length > 0">
                  <label>Sabor *</label>
                  <Dropdown
                    v-model="item.Flavor"
                    :options="getProductFlavors(item.ProductId)"
                    placeholder="Selecione o sabor"
                  />
                </div>

                <div class="field">
                  <label>Quantidade *</label>
                  <InputNumber
                    v-model="item.Quantity"
                    :min="1"
                    :max="99"
                    @update:modelValue="updateItemTotal(index)"
                  />
                </div>

                <div class="field">
                  <label>Preço Unitário</label>
                  <InputNumber
                    v-model="item.UnitPrice"
                    mode="currency"
                    currency="BRL"
                    locale="pt-BR"
                    :disabled="true"
                  />
                </div>

                <div class="field total-field">
                  <label>Total do Item</label>
                  <div class="total-display">
                    <span class="total-value">{{ formatCurrency(item.TotalPrice) }}</span>
                  </div>
                </div>
              </div>

              <!-- Combo Items Flavor Selection -->
              <div v-if="isComboProduct(item.ProductId)" class="combo-flavors-section">
                <h4>Escolha os sabores do combo:</h4>
                <div v-for="(comboItem, comboIdx) in getComboItems(item.ProductId)" :key="comboIdx" class="combo-flavor-row">
                  <div class="combo-item-info">
                    <span class="combo-qty">{{ comboItem.Quantity }}x</span>
                    <span class="combo-name">{{ getProductName(comboItem.ProductId) }}</span>
                  </div>
                  <div v-if="comboItem.AllowFlavorSelection && getProductFlavors(comboItem.ProductId).length > 0" class="combo-flavor-select">
                    <Dropdown
                      v-model="item.ComboFlavors[comboIdx]"
                      :options="getProductFlavors(comboItem.ProductId)"
                      placeholder="Escolha o sabor"
                      class="flavor-dropdown"
                    />
                  </div>
                  <div v-else class="no-flavor">
                    <span class="muted-text">Sem escolha de sabor</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Payment & Summary -->
          <div class="payment-card">
            <h3>Pagamento e Total</h3>
            <div class="payment-grid">
              <div class="field">
                <label>Subtotal</label>
                <InputNumber
                  v-model="orderForm.Subtotal"
                  mode="currency"
                  currency="BRL"
                  locale="pt-BR"
                  :disabled="true"
                />
              </div>

              <div class="field">
                <label for="discount">Desconto (R$)</label>
                <InputNumber
                  id="discount"
                  v-model="orderForm.Discount"
                  mode="currency"
                  currency="BRL"
                  locale="pt-BR"
                  :min="0"
                  :max="orderForm.Subtotal"
                  @input="updateTotal"
                />
              </div>

              <div class="field total-field">
                <label>Total Final</label>
                <InputNumber
                  v-model="orderForm.TotalAmount"
                  mode="currency"
                  currency="BRL"
                  locale="pt-BR"
                  :disabled="true"
                  class="total-amount"
                />
              </div>

              <div class="field">
                <label for="paymentMethod">Forma de Pagamento *</label>
                <Dropdown
                  id="paymentMethod"
                  v-model="orderForm.PaymentMethod"
                  :options="paymentOptions"
                  optionLabel="label"
                  optionValue="value"
                  placeholder="Selecione a forma de pagamento"
                  :class="{ 'p-invalid': submitted && !orderForm.PaymentMethod }"
                />
              </div>

              <div class="field full-width">
                <label for="notes">Observações</label>
                <InputText
                  id="notes"
                  v-model="orderForm.Notes"
                  placeholder="Observações adicionais (opcional)"
                />
              </div>
            </div>
          </div>

          <!-- Form Actions -->
          <div class="form-actions">
            <Button
              label="Limpar Pedido"
              icon="pi pi-times"
              class="p-button-outlined p-button-danger"
              @click="clearForm"
            />
            <Button
              label="Confirmar Pedido"
              icon="pi pi-check"
              class="p-button-success"
              @click="saveOrder"
            />
          </div>
        </div>

        <!-- Sidebar Summary -->
        <div class="sidebar">
          <div class="summary-card">
            <h4>Resumo do Pedido</h4>
            <div v-if="orderForm.items.length === 0" class="empty-summary">
              <p>Adicione itens para ver o resumo</p>
            </div>
            <div v-else class="summary-content">
              <div class="summary-items">
                <div v-for="(item, index) in orderForm.items" :key="index" class="summary-item">
                  <div class="item-info">
                    <span class="item-name">{{ getProductName(item.ProductId) }}</span>
                    <span v-if="item.Flavor" class="item-flavor">{{ item.Flavor }}</span>
                  </div>
                  <div class="item-details">
                    <span class="item-qty">{{ item.Quantity }}x</span>
                    <span class="item-price">{{ formatCurrency(item.TotalPrice) }}</span>
                  </div>
                </div>
              </div>

              <Divider />

              <div class="summary-totals">
                <div class="total-row">
                  <span>Subtotal:</span>
                  <span>{{ formatCurrency(orderForm.Subtotal) }}</span>
                </div>
                <div v-if="orderForm.Discount > 0" class="total-row discount">
                  <span>Desconto:</span>
                  <span>-{{ formatCurrency(orderForm.Discount) }}</span>
                </div>
                <div class="total-row final">
                  <span>Total:</span>
                  <span>{{ formatCurrency(orderForm.TotalAmount) }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick Add Pathfinder -->
          <div class="quick-actions-card">
            <h4>Ações Rápidas</h4>
            <div class="quick-actions">
              <Button
                label="Novo Desbravador"
                icon="pi pi-user-plus"
                class="p-button-outlined action-btn"
                @click="showQuickAddPathfinder = true"
              />
              <Button
                label="Ver Cozinha"
                icon="pi pi-home"
                class="p-button-outlined action-btn"
                @click="$router.push('/kitchen')"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Add Pathfinder Dialog -->
    <Dialog
      v-model:visible="showQuickAddPathfinder"
      header="Adicionar Desbravador Rapidamente"
      :modal="true"
      style="width: 400px"
    >
      <div class="dialog-content">
        <div class="field">
          <label for="quickName">Nome *</label>
          <InputText
            id="quickName"
            v-model="quickPathfinderForm.Name"
            :class="{ 'p-invalid': quickSubmitted && !quickPathfinderForm.Name }"
            style="width: 100%"
          />
          <small v-if="quickSubmitted && !quickPathfinderForm.Name" class="p-error">
            Nome é obrigatório.
          </small>
        </div>
      </div>

      <template #footer>
        <Button
          label="Cancelar"
          icon="pi pi-times"
          class="p-button-text"
          @click="showQuickAddPathfinder = false"
        />
        <Button label="Adicionar" icon="pi pi-check" @click="saveQuickPathfinder" />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { OrderItem, Order } from '@/stores/fundraiser'

// Store and utilities
const fundraiserStore = useFundraiserStore()
const toast = useToast()

// Component state
const submitted = ref(false)
const quickSubmitted = ref(false)
const showQuickAddPathfinder = ref(false)

// Form data
const orderForm = ref({
  PathfinderId: null as string | null,
  CustomerName: '',
  items: [] as OrderItem[],
  Subtotal: 0,
  Discount: 0,
  TotalAmount: 0,
  PaymentMethod: null as Order['PaymentMethod'] | null,
  Date: new Date(),
  Notes: ''
})

const quickPathfinderForm = ref({
  Name: ''
})

// Options for dropdowns
const pathfinderOptions = computed(() => {
  return fundraiserStore.pathfinders.map(pathfinder => ({
    label: pathfinder.Name,
    value: pathfinder.PK
  }))
})

const productOptions = computed(() => {
  return fundraiserStore.products.map(product => ({
    label: `${product.Name} - ${formatCurrency(product.Price)}`,
    value: product.PK
  }))
})

const paymentOptions = ref([
  { label: 'Cartão', value: 'card' as const },
  { label: 'Dinheiro', value: 'cash' as const },
  { label: 'Pix Igreja', value: 'pix-church' as const },
  { label: 'Pix QR Code', value: 'pix-qr' as const }
])

// Methods
const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value || 0)
}

const getProductName = (productId: string) => {
  const product = fundraiserStore.products.find(p => p.PK === productId)
  return product?.Name || 'N/A'
}

const getProductFlavors = (productId: string) => {
  const product = fundraiserStore.products.find(p => p.PK === productId)
  return product?.Flavors || []
}

const isComboProduct = (productId: string) => {
  const product = fundraiserStore.products.find(p => p.PK === productId)
  return product?.Category === 'combo' && product?.ComboItems && product.ComboItems.length > 0
}

const getComboItems = (productId: string) => {
  const product = fundraiserStore.products.find(p => p.PK === productId)
  return product?.ComboItems || []
}

const addItem = () => {
  orderForm.value.items.push({
    ProductId: '',
    Quantity: 1,
    Flavor: '',
    UnitPrice: 0,
    TotalPrice: 0,
    ComboFlavors: []
  } as any) // Temporary type assertion - will be proper OrderItems on save
}

const removeItem = (index: number) => {
  orderForm.value.items.splice(index, 1)
  updateSubtotal()
}

const updateItemProduct = (index: number) => {
  const item = orderForm.value.items[index]
  const product = fundraiserStore.products.find(p => p.PK === item.ProductId)

  if (product) {
    item.UnitPrice = product.Price
    item.Flavor = ''

    // Initialize ComboFlavors array if it's a combo product
    if (product.Category === 'combo' && product.ComboItems) {
      item.ComboFlavors = new Array(product.ComboItems.length).fill('')
    } else {
      item.ComboFlavors = []
    }

    updateItemTotal(index)
  }
}

const updateItemTotal = (index: number) => {
  const item = orderForm.value.items[index]
  item.TotalPrice = item.UnitPrice * item.Quantity
  updateSubtotal()
}

const updateSubtotal = () => {
  orderForm.value.Subtotal = orderForm.value.items.reduce((sum, item) => sum + item.TotalPrice, 0)
  updateTotal()
}

const updateTotal = () => {
  orderForm.value.TotalAmount = Math.max(0, orderForm.value.Subtotal - orderForm.value.Discount)
}

const clearForm = () => {
  orderForm.value = {
    PathfinderId: null,
    CustomerName: '',
    items: [],
    Subtotal: 0,
    Discount: 0,
    TotalAmount: 0,
    PaymentMethod: null,
    Date: new Date(),
    Notes: ''
  }
  submitted.value = false
}

const validateForm = () => {
  return orderForm.value.PathfinderId &&
         orderForm.value.CustomerName?.trim() &&
         orderForm.value.items.length > 0 &&
         orderForm.value.items.every(item => item.ProductId && item.Quantity > 0) &&
         orderForm.value.PaymentMethod
}

const saveOrder = async () => {
  submitted.value = true

  if (!validateForm()) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Preencha todos os campos obrigatórios',
      life: 3000
    })
    return
  }

  try {
    const orderData = {
      PathfinderId: orderForm.value.PathfinderId!,
      CustomerName: orderForm.value.CustomerName.trim(),
      items: orderForm.value.items,
      Subtotal: orderForm.value.Subtotal,
      Discount: orderForm.value.Discount,
      TotalAmount: orderForm.value.TotalAmount,
      PaymentMethod: orderForm.value.PaymentMethod!,
      Status: 'pending' as const,
      Date: orderForm.value.Date.toISOString().split('T')[0],
      Notes: orderForm.value.Notes?.trim()
    }

    await fundraiserStore.addOrder(orderData)

    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Pedido registrado com sucesso!',
      life: 3000
    })

    clearForm()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao registrar pedido',
      life: 3000
    })
  }
}

const saveAsDraft = () => {
  // For now, just save as pending
  saveOrder()
}

const saveQuickPathfinder = async () => {
  quickSubmitted.value = true

  if (!quickPathfinderForm.value.Name?.trim()) {
    return
  }

  try {
    const newPathfinder = await fundraiserStore.addPathfinder({
      Name: quickPathfinderForm.value.Name.trim()
    })
    orderForm.value.PathfinderId = newPathfinder.PK

    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Desbravador adicionado com sucesso!',
      life: 3000
    })

    showQuickAddPathfinder.value = false
    quickPathfinderForm.value.Name = ''
    quickSubmitted.value = false
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao adicionar desbravador',
      life: 3000
    })
  }
}

// Watchers
watch(() => orderForm.value.Discount, updateTotal)
</script>

<style scoped>
.order-entry {
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

.order-form {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 1.5rem;
  overflow-x: hidden;
}

@media (max-width: 1300px) {
  .order-form {
    grid-template-columns: 1fr 280px;
    gap: 1rem;
  }
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.info-card, .items-card, .payment-card {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.info-card h3, .items-card h3, .payment-card h3 {
  margin: 0 0 1.5rem 0;
  color: #2c3e50;
  font-size: 1.25rem;
  font-weight: 600;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1rem;
}

@media (max-width: 600px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
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

.items-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.empty-items {
  text-align: center;
  padding: 3rem 1rem;
  color: #6c757d;
}

.empty-items i {
  font-size: 3rem;
  margin-bottom: 1rem;
  display: block;
}

.item-row {
  border: 1px solid #dee2e6;
  border-radius: 0.75rem;
  padding: 1.25rem;
  margin-bottom: 1.25rem;
  background: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
  overflow-x: auto;
  min-width: 0;
  transition: all 0.2s ease;
  position: relative;
}

.item-row:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.12);
  border-color: #c3d9ff;
}

.item-row::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: linear-gradient(135deg, var(--primary-color, #ef7f47), #f7a169);
  border-radius: 0.75rem 0 0 0.75rem;
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #f1f3f4;
}

.item-number {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: var(--primary-color, #ef7f47);
  font-size: 0.95rem;
}

.item-number i {
  font-size: 1.1rem;
}

.remove-btn {
  padding: 0.4rem !important;
  width: auto !important;
  height: auto !important;
}

.item-grid {
  display: grid;
  grid-template-columns: 2fr 1.2fr 100px 120px 140px;
  gap: 1rem;
  align-items: end;
  min-width: 0;
}

.total-field {
  grid-column: span 1;
}

.total-display {
  padding: 0.75rem;
  background: linear-gradient(135deg, #f8f9fa, #e9ecef);
  border: 2px solid var(--primary-color, #ef7f47);
  border-radius: 0.5rem;
  text-align: center;
}

.total-value {
  font-weight: 700;
  font-size: 1.125rem;
  color: var(--primary-color, #ef7f47);
}

@media (max-width: 1300px) {
  .item-grid {
    grid-template-columns: 1.8fr 1fr 80px 100px 120px;
    gap: 0.75rem;
  }
}

@media (max-width: 1024px) {
  .item-grid {
    grid-template-columns: 1fr;
    gap: 0.75rem;
  }

  .item-grid .field {
    width: 100%;
  }

  .total-display {
    margin-top: 0.5rem;
    padding: 1rem;
  }
  .total-value {
    font-size: 1.25rem;
  }
}

.field-actions {
  display: flex;
  align-items: center;
  justify-content: center;
}

.payment-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 1rem;
}

@media (max-width: 600px) {
  .payment-grid {
    grid-template-columns: 1fr;
  }
}

.total-field {
  grid-column: span 1;
}

.full-width {
  grid-column: 1 / -1;
}

.total-amount :deep(.p-inputnumber-input) {
  font-weight: bold;
  font-size: 1.125rem;
  color: var(--primary-color);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1rem 0;
}

.sidebar {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  position: sticky;
  top: 2rem;
  height: fit-content;
  min-width: 0;
}

.summary-card, .quick-actions-card {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.summary-card h4, .quick-actions-card h4 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
  font-size: 1.125rem;
  font-weight: 600;
}

.empty-summary {
  text-align: center;
  color: #6c757d;
  padding: 1rem 0;
}

.summary-items {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.summary-item {
  display: flex;
  justify-content: space-between;
  align-items: start;
  padding: 0.5rem 0;
}

.item-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.item-name {
  font-weight: 500;
  color: #2c3e50;
}

.item-flavor {
  font-size: 0.875rem;
  color: #6c757d;
}

.item-details {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.25rem;
}

.item-qty {
  font-size: 0.875rem;
  color: #6c757d;
}

.item-price {
  font-weight: 500;
  color: #2c3e50;
}

.summary-totals {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.total-row.discount {
  color: #dc3545;
}

.total-row.final {
  font-weight: bold;
  font-size: 1.125rem;
  color: var(--primary-color);
  padding-top: 0.5rem;
  border-top: 1px solid #e9ecef;
}

.quick-actions {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.action-btn {
  width: 100%;
}

.dialog-content {
  padding: 1rem 0;
}

.p-invalid {
  border-color: #e24c4c;
}

.p-error {
  color: #e24c4c;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

/* Prevent PrimeVue components from overflowing */
.field :deep(.p-dropdown),
.field :deep(.p-inputtext),
.field :deep(.p-inputnumber),
.field :deep(.p-calendar) {
  width: 100%;
  min-width: 0;
}

@media (max-width: 1100px) {
  .order-form {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }

  .sidebar {
    position: static;
    max-width: none;
  }

  .container {
    padding: 0.75rem;
  }
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

  .header-section h2 {
    font-size: 1.5rem;
  }

  .form-grid, .payment-grid {
    grid-template-columns: 1fr;
  }

  .item-grid {
    grid-template-columns: 1fr;
    gap: 0.75rem;
  }

  .form-actions {
    flex-direction: column;
    gap: 0.75rem;
  }

  .info-card, .items-card, .payment-card {
    padding: 1rem;
  }

  .form-section {
    gap: 1rem;
  }

  .item-row {
    padding: 0.75rem;
    overflow-x: visible;
  }

  .items-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }

  .sidebar {
    order: -1;
  }
}

.combo-flavors-section {
  margin-top: 1rem;
  padding: 1rem;
  background: #f0f8ff;
  border-radius: 0.5rem;
  border-left: 4px solid var(--primary-color, #ef7f47);
}

.combo-flavors-section h4 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
  font-size: 1rem;
  font-weight: 600;
}

.combo-flavor-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem;
  background: white;
  border-radius: 0.375rem;
  margin-bottom: 0.75rem;
  gap: 1rem;
}

.combo-item-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex: 1;
}

.combo-qty {
  font-weight: 600;
  color: var(--primary-color, #ef7f47);
}

.combo-name {
  font-weight: 500;
  color: #2c3e50;
}

.combo-flavor-select {
  flex: 1;
  max-width: 250px;
}

.no-flavor {
  flex: 1;
  max-width: 250px;
  text-align: right;
}

.muted-text {
  color: #6c757d;
  font-size: 0.875rem;
  font-style: italic;
}

@media (max-width: 768px) {
  .combo-flavor-row {
    flex-direction: column;
    align-items: flex-start;
  }

  .combo-flavor-select,
  .no-flavor {
    max-width: 100%;
    width: 100%;
  }

  .no-flavor {
    text-align: left;
  }
}

@media (max-width: 480px) {
  .container {
    padding: 0.25rem;
  }

  .info-card, .items-card, .payment-card, .summary-card, .quick-actions-card {
    padding: 0.75rem;
    margin: 0;
  }

  .field label {
    font-size: 0.8rem;
  }

  .item-row {
    padding: 0.75rem;
  }

  .header-section h2 {
    font-size: 1.25rem;
  }
}
</style>