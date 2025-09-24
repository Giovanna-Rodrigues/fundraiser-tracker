<template>
  <div class="products-management">
    <div class="page-header">
      <h1>Gestão de Produtos</h1>
      <button @click="openProductDialog()" class="btn-primary">
        <i class="pi pi-plus"></i>
        Novo Produto
      </button>
    </div>

    <div class="products-grid">
      <div
        v-for="product in products"
        :key="product.PK"
        class="product-card"
      >
        <div class="product-header">
          <h3>{{ product.Name }}</h3>
          <div class="product-actions">
            <button @click="viewPriceHistory(product)" class="btn-icon" title="Ver histórico de preços">
              <i class="pi pi-history"></i>
            </button>
            <button @click="openProductDialog(product)" class="btn-icon" title="Editar">
              <i class="pi pi-pencil"></i>
            </button>
            <button @click="confirmDeleteProduct(product)" class="btn-icon btn-danger" title="Excluir">
              <i class="pi pi-trash"></i>
            </button>
          </div>
        </div>
        <div class="product-body">
          <div class="product-price">R$ {{ product.Price.toFixed(2) }}</div>
          <div class="product-category">{{ getCategoryLabel(product.Category) }}</div>
          <div v-if="product.Description" class="product-description">
            {{ product.Description }}
          </div>
          <div v-if="product.Flavors && product.Flavors.length > 0" class="product-flavors">
            <strong>Sabores:</strong> {{ product.Flavors.join(', ') }}
          </div>
          <div v-if="product.Category === 'combo' && product.ComboItems && product.ComboItems.length > 0" class="product-combo">
            <strong>Combo contém:</strong>
            <ul>
              <li v-for="(item, idx) in product.ComboItems" :key="idx">
                {{ item.Quantity }}x {{ getProductName(item.ProductId) }}
                <span v-if="item.AllowFlavorSelection" class="flavor-tag">✓ Com sabor</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <Dialog
      v-model:visible="showProductDialog"
      modal
      :header="editingProduct ? 'Editar Produto' : 'Novo Produto'"
      :style="{ width: '600px' }"
    >
      <div class="product-form">
        <div class="form-group">
          <label>Nome do Produto</label>
          <input
            v-model="productForm.Name"
            type="text"
            placeholder="Ex: Mini Pizza"
            class="form-control"
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Preço (R$)</label>
            <input
              v-model.number="productForm.Price"
              type="number"
              step="0.01"
              placeholder="15.00"
              class="form-control"
            />
          </div>

          <div class="form-group">
            <label>Categoria</label>
            <select v-model="productForm.Category" class="form-control">
              <option value="pizza">Pizza</option>
              <option value="pastry">Pastel</option>
              <option value="ice-cream">Sorvete</option>
              <option value="beverage">Bebida</option>
              <option value="combo">Combo</option>
              <option value="other">Outro</option>
            </select>
          </div>
        </div>

        <div class="form-group" v-if="productForm.Category !== 'combo'">
          <label>Sabores (separados por vírgula)</label>
          <input
            v-model="flavorsInput"
            type="text"
            placeholder="Ex: Margherita, Pepperoni, Calabresa"
            class="form-control"
          />
        </div>

        <div class="form-group">
          <label>Descrição</label>
          <textarea
            v-model="productForm.Description"
            rows="2"
            placeholder="Descrição do produto"
            class="form-control"
          ></textarea>
        </div>

        <!-- Combo Items Section -->
        <div v-if="productForm.Category === 'combo'" class="combo-section">
          <div class="section-header">
            <label>Itens do Combo</label>
            <button type="button" @click="addComboItem" class="btn-sm btn-success">
              <i class="pi pi-plus"></i> Adicionar Item
            </button>
          </div>

          <div v-if="productForm.ComboItems && productForm.ComboItems.length === 0" class="empty-combo">
            Nenhum item no combo. Clique em "Adicionar Item" para começar.
          </div>

          <div v-for="(item, index) in productForm.ComboItems" :key="index" class="combo-item">
            <div class="combo-item-header">
              <span>Item {{ index + 1 }}</span>
              <button type="button" @click="removeComboItem(index)" class="btn-icon btn-danger">
                <i class="pi pi-trash"></i>
              </button>
            </div>

            <div class="combo-item-body">
              <div class="form-group">
                <label>Produto</label>
                <select v-model="item.ProductId" class="form-control">
                  <option value="">Selecione um produto</option>
                  <option v-for="prod in nonComboProducts" :key="prod.PK" :value="prod.PK">
                    {{ prod.Name }} - R$ {{ prod.Price.toFixed(2) }}
                  </option>
                </select>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label>Quantidade</label>
                  <input
                    v-model.number="item.Quantity"
                    type="number"
                    min="1"
                    class="form-control"
                  />
                </div>

                <div class="form-group checkbox-group">
                  <label>
                    <input
                      v-model="item.AllowFlavorSelection"
                      type="checkbox"
                    />
                    Permitir escolha de sabor
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-if="editingProduct" class="form-group">
          <label>Nota sobre mudança de preço</label>
          <input
            v-model="productForm.PriceNote"
            type="text"
            placeholder="Ex: Novo preço para campanha 2025"
            class="form-control"
          />
        </div>
      </div>

      <template #footer>
        <button @click="showProductDialog = false" class="btn-secondary">Cancelar</button>
        <button @click="saveProduct" class="btn-primary">Salvar</button>
      </template>
    </Dialog>

    <Dialog
      v-model:visible="showPriceHistoryDialog"
      modal
      header="Histórico de Preços"
      :style="{ width: '800px' }"
    >
      <div v-if="selectedProductHistory" class="price-history">
        <h3>{{ selectedProductHistory.Name }}</h3>
        <div class="history-list">
          <div
            v-for="history in priceHistory"
            :key="history.PK"
            class="history-item"
          >
            <div class="history-date">
              {{ formatDate(history.EffectiveDate) }}
            </div>
            <div class="history-price">R$ {{ history.Price.toFixed(2) }}</div>
            <div v-if="history.Notes" class="history-notes">{{ history.Notes }}</div>
            <div v-if="history.OrderId" class="history-order">
              Pedido: {{ history.OrderId }}
            </div>
          </div>
        </div>
      </div>
    </Dialog>

    <Dialog
      v-model:visible="showDeleteDialog"
      modal
      header="Confirmar Exclusão"
      :style="{ width: '400px' }"
    >
      <p>Tem certeza que deseja excluir o produto <strong>{{ productToDelete?.Name }}</strong>?</p>
      <template #footer>
        <button @click="showDeleteDialog = false" class="btn-secondary">Cancelar</button>
        <button @click="deleteProduct" class="btn-danger">Excluir</button>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useFundraiserStore } from '@/stores/fundraiser'
import type { Product } from '@/stores/fundraiser'
import Dialog from 'primevue/dialog'

const route = useRoute()
const fundraiserStore = useFundraiserStore()

const products = computed(() => fundraiserStore.products)
const showProductDialog = ref(false)
const showPriceHistoryDialog = ref(false)
const showDeleteDialog = ref(false)
const editingProduct = ref<Product | null>(null)
const selectedProductHistory = ref<Product | null>(null)
const productToDelete = ref<Product | null>(null)
const priceHistory = ref<any[]>([])
const flavorsInput = ref('')

interface ProductForm {
  Name: string
  Price: number
  Category: 'pizza' | 'pastry' | 'ice-cream' | 'beverage' | 'combo' | 'other'
  Flavors: string[]
  Description?: string
  ComboItems?: Array<{
    ProductId: string
    Quantity: number
    AllowFlavorSelection?: boolean
  }>
  PriceNote?: string
}

const productForm = ref<ProductForm>({
  Name: '',
  Price: 0,
  Category: 'pizza',
  Flavors: [],
  Description: '',
  ComboItems: [],
  PriceNote: ''
})

const nonComboProducts = computed(() => {
  return fundraiserStore.products.filter(p => p.Category !== 'combo')
})

const openProductDialog = (product?: Product) => {
  if (product) {
    editingProduct.value = product
    productForm.value = {
      Name: product.Name,
      Price: product.Price,
      Category: product.Category,
      Flavors: product.Flavors || [],
      Description: product.Description || '',
      ComboItems: product.ComboItems ? [...product.ComboItems] : [],
      PriceNote: ''
    }
    flavorsInput.value = product.Flavors?.join(', ') || ''
  } else {
    editingProduct.value = null
    productForm.value = {
      Name: '',
      Price: 0,
      Category: 'pizza',
      Flavors: [],
      Description: '',
      ComboItems: [],
      PriceNote: ''
    }
    flavorsInput.value = ''
  }
  showProductDialog.value = true
}

const addComboItem = () => {
  if (!productForm.value.ComboItems) {
    productForm.value.ComboItems = []
  }
  productForm.value.ComboItems.push({
    ProductId: '',
    Quantity: 1,
    AllowFlavorSelection: false
  })
}

const removeComboItem = (index: number) => {
  productForm.value.ComboItems?.splice(index, 1)
}

const getProductName = (productId: string) => {
  const product = fundraiserStore.products.find(p => p.PK === productId)
  return product?.Name || 'N/A'
}

const saveProduct = async () => {
  const flavors = productForm.value.Category !== 'combo'
    ? flavorsInput.value
        .split(',')
        .map(f => f.trim())
        .filter(f => f.length > 0)
    : []

  const productData: any = {
    Name: productForm.value.Name,
    Price: productForm.value.Price,
    Category: productForm.value.Category,
    Flavors: flavors,
    Description: productForm.value.Description || null
  }

  // Add combo items if it's a combo product
  if (productForm.value.Category === 'combo' && productForm.value.ComboItems) {
    productData.ComboItems = productForm.value.ComboItems.filter(item => item.ProductId)
  }

  if (editingProduct.value) {
    await fundraiserStore.updateProduct(editingProduct.value.PK, productData, productForm.value.PriceNote)
  } else {
    await fundraiserStore.addProduct(productData)
  }

  showProductDialog.value = false
}

const viewPriceHistory = async (product: Product) => {
  selectedProductHistory.value = product
  priceHistory.value = await fundraiserStore.getPriceHistory(product.PK)
  showPriceHistoryDialog.value = true
}

const confirmDeleteProduct = (product: Product) => {
  productToDelete.value = product
  showDeleteDialog.value = true
}

const deleteProduct = async () => {
  if (productToDelete.value) {
    await fundraiserStore.deleteProduct(productToDelete.value.PK)
    showDeleteDialog.value = false
    productToDelete.value = null
  }
}

const getCategoryLabel = (category: string) => {
  const labels: Record<string, string> = {
    pizza: 'Pizza',
    pastry: 'Pastel',
    'ice-cream': 'Sorvete',
    beverage: 'Bebida',
    combo: 'Combo',
    other: 'Outro'
  }
  return labels[category] || category
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('pt-BR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  fundraiserStore.loadFromSupabase()

  if (route.query.fromCalculator === 'true') {
    const name = route.query.name as string
    const price = parseFloat(route.query.price as string)

    if (name && price) {
      productForm.value = {
        Name: name,
        Price: price,
        Category: 'other',
        Flavors: [],
        PriceNote: 'Preço calculado baseado em custos'
      }
      showProductDialog.value = true
    }
  }
})
</script>

<style scoped>
.products-management {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #2c3e50;
  font-size: 2rem;
}

.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.product-card {
  background: white;
  border-radius: 1rem;
  padding: 1.5rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.product-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

.product-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.product-header h3 {
  color: #2c3e50;
  margin: 0;
}

.product-actions {
  display: flex;
  gap: 0.5rem;
}

.product-body {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.product-price {
  font-size: 1.5rem;
  font-weight: bold;
  color: #28a745;
}

.product-category {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  background: #e9ecef;
  border-radius: 1rem;
  font-size: 0.875rem;
  width: fit-content;
}

.product-flavors {
  font-size: 0.875rem;
  color: #6c757d;
  margin-top: 0.5rem;
}

.btn-primary {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  background: #ef7f47;
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s ease;
}

.btn-primary:hover {
  background: #e56a2e;
}

.btn-secondary {
  padding: 0.75rem 1.5rem;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s ease;
}

.btn-secondary:hover {
  background: #5a6268;
}

.btn-icon {
  background: transparent;
  border: none;
  color: #6c757d;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 0.25rem;
  transition: all 0.2s ease;
}

.btn-icon:hover {
  background: #f8f9fa;
  color: #2c3e50;
}

.btn-danger {
  color: #dc3545;
}

.btn-danger:hover {
  background: #ffe6e8;
  color: #dc3545;
}

.product-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-weight: 600;
  color: #495057;
}

.form-control {
  padding: 0.75rem;
  border: 1px solid #dee2e6;
  border-radius: 0.5rem;
  font-size: 1rem;
}

.form-control:focus {
  border-color: #ef7f47;
  outline: none;
  box-shadow: 0 0 0 3px rgba(239, 127, 71, 0.1);
}

.price-history h3 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.history-item {
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 0.5rem;
  border-left: 4px solid #ef7f47;
}

.history-date {
  font-size: 0.875rem;
  color: #6c757d;
  margin-bottom: 0.25rem;
}

.history-price {
  font-size: 1.25rem;
  font-weight: bold;
  color: #28a745;
  margin-bottom: 0.25rem;
}

.history-notes {
  font-size: 0.875rem;
  color: #495057;
  margin-top: 0.5rem;
}

.history-order {
  font-size: 0.75rem;
  color: #6c757d;
  margin-top: 0.25rem;
}

.product-description {
  font-size: 0.875rem;
  color: #6c757d;
  margin-bottom: 0.5rem;
}

.product-combo {
  margin-top: 0.75rem;
  padding: 0.75rem;
  background: #f8f9fa;
  border-radius: 0.5rem;
}

.product-combo ul {
  margin: 0.5rem 0 0 1.5rem;
  padding: 0;
}

.product-combo li {
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
}

.flavor-tag {
  display: inline-block;
  margin-left: 0.5rem;
  padding: 0.125rem 0.5rem;
  background: #28a745;
  color: white;
  border-radius: 0.25rem;
  font-size: 0.75rem;
}

.combo-section {
  margin-top: 1.5rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 0.5rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.section-header label {
  font-weight: 600;
  color: #2c3e50;
  margin: 0;
}

.empty-combo {
  text-align: center;
  padding: 2rem;
  color: #6c757d;
  font-style: italic;
}

.combo-item {
  background: white;
  border-radius: 0.5rem;
  padding: 1rem;
  margin-bottom: 1rem;
  border: 1px solid #dee2e6;
}

.combo-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #dee2e6;
  font-weight: 600;
}

.combo-item-body {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.checkbox-group {
  display: flex;
  align-items: center;
}

.checkbox-group label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
  cursor: pointer;
}

.checkbox-group input[type="checkbox"] {
  width: auto;
  cursor: pointer;
}

@media (max-width: 768px) {
  .products-management {
    padding: 1rem;
  }

  .products-grid {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>