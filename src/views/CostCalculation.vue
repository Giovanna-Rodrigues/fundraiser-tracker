<template>
  <div class="cost-calculation">
    <div class="page-header">
      <h1>Cálculo de Custos</h1>
      <p>Calcule o custo dos ingredientes e determine preços de venda para obter lucro</p>
    </div>

    <div class="calculation-container">
      <!-- Ingredient Input Section -->
      <div class="ingredient-section">
        <h2>Ingredientes</h2>
        <div class="ingredient-grid">
          <div
            v-for="(ingredient, index) in ingredients"
            :key="index"
            class="ingredient-card"
          >
            <div class="ingredient-header">
              <input
                v-model="ingredient.name"
                placeholder="Nome do ingrediente"
                class="ingredient-name"
              />
              <button @click="removeIngredient(index)" class="remove-btn">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <div class="ingredient-inputs">
              <div class="input-group">
                <label>Quantidade comprada</label>
                <input
                  type="number"
                  v-model.number="ingredient.purchased"
                  placeholder="Ex: 1000"
                  step="0.01"
                />
                <select v-model="ingredient.purchasedUnit">
                  <option value="g">gramas</option>
                  <option value="kg">kg</option>
                  <option value="ml">ml</option>
                  <option value="l">litros</option>
                  <option value="unidades">unidades</option>
                </select>
              </div>

              <div class="input-group">
                <label>Preço pago (R$)</label>
                <input
                  type="number"
                  v-model.number="ingredient.price"
                  placeholder="Ex: 15.50"
                  step="0.01"
                />
              </div>

              <div class="input-group">
                <label>Quantidade usada por produto</label>
                <input
                  type="number"
                  v-model.number="ingredient.usedPerProduct"
                  placeholder="Ex: 100"
                  step="0.01"
                />
                <select v-model="ingredient.usedUnit">
                  <option value="g">gramas</option>
                  <option value="kg">kg</option>
                  <option value="ml">ml</option>
                  <option value="l">litros</option>
                  <option value="unidades">unidades</option>
                </select>
              </div>
            </div>

            <div class="ingredient-result">
              <div class="cost-per-product">
                <strong>Custo por produto: R$ {{ getCostPerProduct(ingredient).toFixed(2) }}</strong>
              </div>
            </div>
          </div>
        </div>

        <button @click="addIngredient" class="add-ingredient-btn">
          <i class="pi pi-plus"></i>
          Adicionar Ingrediente
        </button>
      </div>

      <!-- Results Section -->
      <div class="results-section">
        <h2>Resultados</h2>

        <div class="results-grid">
          <div class="result-card">
            <h3>Custo Total por Produto</h3>
            <div class="result-value">R$ {{ totalCostPerProduct.toFixed(2) }}</div>
          </div>

          <div class="result-card">
            <h3>Produtos Possíveis</h3>
            <div class="result-value">{{ maxProductsPossible }}</div>
          </div>

          <div class="result-card">
            <h3>Investimento Total</h3>
            <div class="result-value">R$ {{ totalInvestment.toFixed(2) }}</div>
          </div>
        </div>

        <div class="pricing-section">
          <h3>Sugestões de Preço de Venda</h3>
          <div class="pricing-grid">
            <div class="pricing-option">
              <h4>Margem 50%</h4>
              <div class="price">R$ {{ (totalCostPerProduct * 1.5).toFixed(2) }}</div>
              <div class="profit">Lucro: R$ {{ (totalCostPerProduct * 0.5).toFixed(2) }}</div>
            </div>

            <div class="pricing-option">
              <h4>Margem 75%</h4>
              <div class="price">R$ {{ (totalCostPerProduct * 1.75).toFixed(2) }}</div>
              <div class="profit">Lucro: R$ {{ (totalCostPerProduct * 0.75).toFixed(2) }}</div>
            </div>

            <div class="pricing-option recommended">
              <h4>Margem 100%</h4>
              <div class="price">R$ {{ (totalCostPerProduct * 2).toFixed(2) }}</div>
              <div class="profit">Lucro: R$ {{ totalCostPerProduct.toFixed(2) }}</div>
              <div class="recommended-badge">Recomendado</div>
            </div>

            <div class="pricing-option">
              <h4>Margem 150%</h4>
              <div class="price">R$ {{ (totalCostPerProduct * 2.5).toFixed(2) }}</div>
              <div class="profit">Lucro: R$ {{ (totalCostPerProduct * 1.5).toFixed(2) }}</div>
            </div>
          </div>
        </div>

        <div class="custom-pricing">
          <h3>Preço Personalizado</h3>
          <div class="custom-price-input">
            <label>Preço de venda desejado (R$):</label>
            <input
              type="number"
              v-model.number="customPrice"
              placeholder="Ex: 25.00"
              step="0.01"
            />
          </div>
          <div v-if="customPrice > 0" class="custom-results">
            <div class="custom-result">
              <strong>Margem: {{ getMarginPercentage(customPrice).toFixed(1) }}%</strong>
            </div>
            <div class="custom-result">
              <strong>Lucro por produto: R$ {{ (customPrice - totalCostPerProduct).toFixed(2) }}</strong>
            </div>
            <div class="custom-result">
              <strong>Lucro total possível: R$ {{ ((customPrice - totalCostPerProduct) * maxProductsPossible).toFixed(2) }}</strong>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

interface Ingredient {
  name: string
  purchased: number
  purchasedUnit: string
  price: number
  usedPerProduct: number
  usedUnit: string
}

const ingredients = ref<Ingredient[]>([
  {
    name: 'Queijo',
    purchased: 1,
    purchasedUnit: 'kg',
    price: 25.00,
    usedPerProduct: 100,
    usedUnit: 'g'
  },
  {
    name: 'Molho de Tomate',
    purchased: 500,
    purchasedUnit: 'g',
    price: 4.50,
    usedPerProduct: 50,
    usedUnit: 'g'
  }
])

const customPrice = ref(0)

const addIngredient = () => {
  ingredients.value.push({
    name: '',
    purchased: 0,
    purchasedUnit: 'g',
    price: 0,
    usedPerProduct: 0,
    usedUnit: 'g'
  })
}

const removeIngredient = (index: number) => {
  ingredients.value.splice(index, 1)
}

const convertToGrams = (amount: number, unit: string): number => {
  switch (unit) {
    case 'kg': return amount * 1000
    case 'l': return amount * 1000
    case 'ml': return amount
    case 'g': return amount
    case 'unidades': return amount
    default: return amount
  }
}

const getCostPerProduct = (ingredient: Ingredient): number => {
  if (!ingredient.purchased || !ingredient.price || !ingredient.usedPerProduct) return 0

  const purchasedInBaseUnit = convertToGrams(ingredient.purchased, ingredient.purchasedUnit)
  const usedInBaseUnit = convertToGrams(ingredient.usedPerProduct, ingredient.usedUnit)

  if (purchasedInBaseUnit === 0) return 0

  const costPerUnit = ingredient.price / purchasedInBaseUnit
  return costPerUnit * usedInBaseUnit
}

const totalCostPerProduct = computed(() => {
  return ingredients.value.reduce((total, ingredient) => {
    return total + getCostPerProduct(ingredient)
  }, 0)
})

const maxProductsPossible = computed(() => {
  if (ingredients.value.length === 0) return 0

  return Math.floor(Math.min(...ingredients.value.map(ingredient => {
    if (!ingredient.purchased || !ingredient.usedPerProduct) return 0

    const purchasedInBaseUnit = convertToGrams(ingredient.purchased, ingredient.purchasedUnit)
    const usedInBaseUnit = convertToGrams(ingredient.usedPerProduct, ingredient.usedUnit)

    if (usedInBaseUnit === 0) return 0

    return purchasedInBaseUnit / usedInBaseUnit
  })))
})

const totalInvestment = computed(() => {
  return ingredients.value.reduce((total, ingredient) => {
    return total + (ingredient.price || 0)
  }, 0)
})

const getMarginPercentage = (sellPrice: number): number => {
  if (totalCostPerProduct.value === 0) return 0
  return ((sellPrice - totalCostPerProduct.value) / totalCostPerProduct.value) * 100
}
</script>

<style scoped>
.cost-calculation {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
  background: #f8f9fa;
  min-height: 100vh;
}

.page-header {
  text-align: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #2c3e50;
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.page-header p {
  color: #6c757d;
  font-size: 1.1rem;
}

.calculation-container {
  display: grid;
  grid-template-columns: 1fr 400px;
  gap: 2rem;
}

.ingredient-section {
  background: white;
  border-radius: 1rem;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

.ingredient-section h2 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
  font-size: 1.5rem;
}

.ingredient-grid {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.ingredient-card {
  border: 2px solid #e9ecef;
  border-radius: 0.75rem;
  padding: 1.5rem;
  background: #f8f9fa;
  transition: all 0.2s ease;
}

.ingredient-card:hover {
  border-color: #ef7f47;
  box-shadow: 0 2px 10px rgba(239, 127, 71, 0.1);
}

.ingredient-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.ingredient-name {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #dee2e6;
  border-radius: 0.5rem;
  font-size: 1.1rem;
  font-weight: 600;
  background: white;
}

.remove-btn {
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s ease;
}

.remove-btn:hover {
  background: #c82333;
}

.ingredient-inputs {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.input-group label {
  font-weight: 600;
  color: #495057;
  font-size: 0.9rem;
}

.input-group input,
.input-group select {
  padding: 0.75rem;
  border: 1px solid #dee2e6;
  border-radius: 0.5rem;
  font-size: 0.9rem;
}

.input-group input:focus,
.input-group select:focus {
  border-color: #ef7f47;
  outline: none;
  box-shadow: 0 0 0 3px rgba(239, 127, 71, 0.1);
}

.ingredient-result {
  padding: 1rem;
  background: white;
  border-radius: 0.5rem;
  border-left: 4px solid #28a745;
}

.cost-per-product {
  color: #28a745;
  font-size: 1.1rem;
}

.add-ingredient-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 1.5rem;
  background: #ef7f47;
  color: white;
  border: none;
  border-radius: 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s ease;
  width: fit-content;
}

.add-ingredient-btn:hover {
  background: #e56a2e;
}

.results-section {
  background: white;
  border-radius: 1rem;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  height: fit-content;
}

.results-section h2 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
  font-size: 1.5rem;
}

.results-grid {
  display: grid;
  gap: 1rem;
  margin-bottom: 2rem;
}

.result-card {
  padding: 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 0.75rem;
  text-align: center;
}

.result-card h3 {
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  opacity: 0.9;
}

.result-value {
  font-size: 1.8rem;
  font-weight: bold;
}

.pricing-section {
  margin-bottom: 2rem;
}

.pricing-section h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
  font-size: 1.2rem;
}

.pricing-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.pricing-option {
  padding: 1rem;
  border: 2px solid #e9ecef;
  border-radius: 0.75rem;
  text-align: center;
  position: relative;
  transition: all 0.2s ease;
}

.pricing-option:hover {
  border-color: #ef7f47;
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(239, 127, 71, 0.2);
}

.pricing-option.recommended {
  border-color: #28a745;
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
}

.pricing-option h4 {
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.pricing-option .price {
  font-size: 1.5rem;
  font-weight: bold;
  margin-bottom: 0.25rem;
}

.pricing-option .profit {
  font-size: 0.9rem;
  opacity: 0.8;
}

.recommended-badge {
  position: absolute;
  top: -10px;
  right: -10px;
  background: #ffc107;
  color: #212529;
  padding: 0.25rem 0.5rem;
  border-radius: 1rem;
  font-size: 0.7rem;
  font-weight: bold;
}

.custom-pricing h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
  font-size: 1.2rem;
}

.custom-price-input {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.custom-price-input label {
  font-weight: 600;
  color: #495057;
}

.custom-price-input input {
  padding: 0.75rem;
  border: 1px solid #dee2e6;
  border-radius: 0.5rem;
  font-size: 1rem;
}

.custom-results {
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 0.5rem;
  border-left: 4px solid #17a2b8;
}

.custom-result {
  margin-bottom: 0.5rem;
  color: #17a2b8;
}

@media (max-width: 768px) {
  .cost-calculation {
    padding: 1rem;
  }

  .calculation-container {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }

  .ingredient-inputs {
    grid-template-columns: 1fr;
  }

  .pricing-grid {
    grid-template-columns: 1fr;
  }

  .page-header h1 {
    font-size: 2rem;
  }
}
</style>