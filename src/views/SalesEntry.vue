<template>
  <div class="sales-entry">
    <div class="header-section">
      <h2>Registrar Nova Venda</h2>
      <Button
        label="Voltar ao Dashboard"
        icon="pi pi-arrow-left"
        class="p-button-outlined"
        @click="$router.push('/')"
      />
    </div>

    <div class="content-grid">
      <div class="form-section">
        <div class="form-card">
          <h3>Dados da Venda</h3>

          <div class="form-grid">
            <div class="field">
              <label for="pathfinder">Desbravador *</label>
              <Dropdown
                id="pathfinder"
                v-model="saleForm.pathfinderId"
                :options="pathfinderOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="Selecione um desbravador"
                :class="{ 'p-invalid': submitted && !saleForm.pathfinderId }"
                :filter="true"
                filterBy="label"
              />
              <small v-if="submitted && !saleForm.pathfinderId" class="p-error">
                Desbravador é obrigatório.
              </small>
            </div>

            <div class="field">
              <label for="date">Data da Venda *</label>
              <Calendar
                id="date"
                v-model="saleForm.date"
                dateFormat="dd/mm/yy"
                :class="{ 'p-invalid': submitted && !saleForm.date }"
              />
              <small v-if="submitted && !saleForm.date" class="p-error">Data é obrigatória.</small>
            </div>

            <div class="field">
              <label for="product">Produto *</label>
              <Dropdown
                id="product"
                v-model="saleForm.productId"
                :options="productOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="Selecione um produto"
                :class="{ 'p-invalid': submitted && !saleForm.productId }"
                @change="updateTotalAmount"
              />
              <small v-if="submitted && !saleForm.productId" class="p-error">
                Produto é obrigatório.
              </small>
            </div>

            <div class="field">
              <label for="quantity">Quantidade *</label>
              <InputNumber
                id="quantity"
                v-model="saleForm.quantity"
                :min="1"
                :max="999"
                :class="{ 'p-invalid': submitted && (!saleForm.quantity || saleForm.quantity < 1) }"
                @input="updateTotalAmount"
              />
              <small v-if="submitted && (!saleForm.quantity || saleForm.quantity < 1)" class="p-error">
                Quantidade deve ser maior que 0.
              </small>
            </div>

            <div class="field">
              <label for="paymentMethod">Forma de Pagamento *</label>
              <Dropdown
                id="paymentMethod"
                v-model="saleForm.paymentMethod"
                :options="paymentOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="Selecione a forma de pagamento"
                :class="{ 'p-invalid': submitted && !saleForm.paymentMethod }"
              />
              <small v-if="submitted && !saleForm.paymentMethod" class="p-error">
                Forma de pagamento é obrigatória.
              </small>
            </div>

            <div class="field">
              <label for="totalAmount">Valor Total</label>
              <InputNumber
                id="totalAmount"
                v-model="saleForm.totalAmount"
                mode="currency"
                currency="BRL"
                locale="pt-BR"
                :disabled="true"
              />
            </div>
          </div>

          <div class="form-actions">
            <Button label="Limpar" icon="pi pi-times" class="p-button-outlined" @click="clearForm" />
            <Button label="Registrar Venda" icon="pi pi-check" @click="saveSale" />
          </div>
        </div>
      </div>

      <div class="sidebar-section">
        <!-- Product Summary -->
        <div class="summary-card">
          <h3>Resumo do Produto</h3>
          <div v-if="selectedProduct" class="product-summary">
            <div class="product-header">
              <h4>{{ selectedProduct.Name }}</h4>
              <Tag :value="selectedProduct.Category" :severity="getProductSeverity(selectedProduct.Category)" />
            </div>
            <div class="product-details">
              <div class="detail-row">
                <span>Preço unitário:</span>
                <span class="value">{{ formatCurrency(selectedProduct.Price) }}</span>
              </div>
              <div v-if="saleForm.quantity > 0" class="detail-row">
                <span>Quantidade:</span>
                <span class="value">{{ saleForm.quantity }}</span>
              </div>
              <Divider />
              <div class="detail-row total">
                <span>Total:</span>
                <span class="value primary">{{ formatCurrency(saleForm.totalAmount) }}</span>
              </div>
            </div>
          </div>
          <div v-else class="empty-state">
            <i class="pi pi-shopping-cart"></i>
            <p>Selecione um produto para ver o resumo</p>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="actions-card">
          <h4>Ações Rápidas</h4>
          <div class="quick-actions">
            <Button
              label="Novo Desbravador"
              icon="pi pi-user-plus"
              class="p-button-outlined action-btn"
              @click="showQuickAddPathfinder = true"
            />
            <Button
              label="Ver Ranking"
              icon="pi pi-trophy"
              class="p-button-outlined action-btn"
              @click="$router.push('/leaderboard')"
            />
            <Button
              label="Histórico de Vendas"
              icon="pi pi-list"
              class="p-button-outlined action-btn"
              @click="$router.push('/sales-list')"
            />
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
            v-model="quickPathfinderForm.name"
            :class="{ 'p-invalid': quickSubmitted && !quickPathfinderForm.name }"
            style="width: 100%"
          />
          <small v-if="quickSubmitted && !quickPathfinderForm.name" class="p-error">
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
import { ref, computed, onMounted, watch } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { Product } from '@/stores/fundraiser'

// Store and utilities
const fundraiserStore = useFundraiserStore()
const toast = useToast()

// Component state
const submitted = ref(false)
const quickSubmitted = ref(false)
const showQuickAddPathfinder = ref(false)

// Form data
const saleForm = ref({
  pathfinderId: null as string | null,
  productId: null as string | null,
  quantity: 1,
  paymentMethod: null as 'card' | 'pix' | null,
  totalAmount: 0,
  date: new Date()
})

const quickPathfinderForm = ref({
  name: ''
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
  { label: 'Pix', value: 'pix' as const }
])

// Computed properties
const selectedProduct = computed((): Product | null => {
  if (!saleForm.value.productId) return null
  return fundraiserStore.products.find(p => p.PK === saleForm.value.productId) || null
})

// Methods
const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value || 0)
}

const getProductSeverity = (category: string) => {
  const severities: Record<string, string> = {
    pizza: 'success',
    pastry: 'info'
  }
  return severities[category] || 'secondary'
}

const updateTotalAmount = () => {
  if (selectedProduct.value && saleForm.value.quantity > 0) {
    saleForm.value.totalAmount = selectedProduct.value.Price * saleForm.value.quantity
  } else {
    saleForm.value.totalAmount = 0
  }
}

const clearForm = () => {
  saleForm.value = {
    pathfinderId: null as string | null,
    productId: null as string | null,
    quantity: 1,
    paymentMethod: null as 'card' | 'pix' | null,
    totalAmount: 0,
    date: new Date()
  }
  submitted.value = false
}

const saveSale = async () => {
  submitted.value = true

  // Validation
  if (!saleForm.value.pathfinderId || !saleForm.value.productId ||
      !saleForm.value.quantity || saleForm.value.quantity < 1 ||
      !saleForm.value.paymentMethod || !saleForm.value.date) {
    return
  }

  try {
    const paymentMethod = saleForm.value.paymentMethod === 'pix' ? 'pix-qr' : saleForm.value.paymentMethod

    await fundraiserStore.addOrder({
      PathfinderId: saleForm.value.pathfinderId!,
      CustomerName: 'Cliente', // Default customer name for legacy sales
      Subtotal: saleForm.value.totalAmount,
      Discount: 0,
      TotalAmount: saleForm.value.totalAmount,
      PaymentMethod: paymentMethod as 'card' | 'cash' | 'pix-church' | 'pix-qr',
      Status: 'delivered' as const,
      Date: saleForm.value.date.toISOString().split('T')[0]
    })
    // TODO: Save order items to OrderItemsTable

    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Venda registrada com sucesso!',
      life: 3000
    })

    clearForm()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao registrar venda',
      life: 3000
    })
  }
}

const saveQuickPathfinder = async () => {
  quickSubmitted.value = true

  if (!quickPathfinderForm.value.name?.trim()) {
    return
  }

  try {
    const newPathfinder = await fundraiserStore.addPathfinder({
      Name: quickPathfinderForm.value.name.trim()
    })
    saleForm.value.pathfinderId = newPathfinder.PK

    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Desbravador adicionado com sucesso!',
      life: 3000
    })

    showQuickAddPathfinder.value = false
    quickPathfinderForm.value.name = ''
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
watch(() => saleForm.value.productId, updateTotalAmount)
watch(() => saleForm.value.quantity, updateTotalAmount)

onMounted(() => {
  // Component is ready
})
</script>

<style scoped>
.sales-entry {
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

.content-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
}

.form-card, .summary-card, .actions-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.form-card h3, .summary-card h3 {
  margin: 0 0 1.5rem 0;
  color: #2c3e50;
}

.actions-card h4 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
}

.field label {
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid #e9ecef;
}

.product-summary {
  background: #f8f9fa;
  border-radius: 0.5rem;
  padding: 1rem;
}

.product-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.product-header h4 {
  margin: 0;
  color: #2c3e50;
}

.product-details {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.detail-row.total {
  font-size: 1.25rem;
  font-weight: bold;
}

.detail-row .value {
  font-weight: 500;
}

.detail-row .value.primary {
  color: var(--primary-color);
}

.empty-state {
  text-align: center;
  color: #6c757d;
  padding: 2rem;
}

.empty-state i {
  font-size: 3rem;
  margin-bottom: 1rem;
  display: block;
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

@media (max-width: 768px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
}
</style>