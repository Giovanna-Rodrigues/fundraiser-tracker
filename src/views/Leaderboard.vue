<template>
  <div class="leaderboard">
    <div class="header-section">
      <h2>🏆 Ranking de Vendas</h2>
      <div class="header-actions">
        <Button
          label="Exportar Ranking"
          icon="pi pi-download"
          class="p-button-outlined"
          @click="exportRanking"
        />
        <Button
          label="Voltar ao Dashboard"
          icon="pi pi-arrow-left"
          class="p-button-outlined"
          @click="$router.push('/')"
        />
      </div>
    </div>

    <!-- Top 3 Podium -->
    <div v-if="salesByPathfinder.length > 0" class="podium-section">
      <div class="podium-container">
        <!-- 2nd Place -->
        <div v-if="salesByPathfinder[1]" class="podium-item second-place">
          <div class="podium-medal">
            <i class="pi pi-trophy trophy-silver"></i>
            <span class="position-number">2</span>
          </div>
          <div class="podium-info">
            <h4>{{ salesByPathfinder[1].pathfinder.Name }}</h4>
            <div class="amount">{{ formatCurrency(salesByPathfinder[1].totalAmount) }}</div>
            <div class="products">{{ salesByPathfinder[1].totalQuantity }} produtos</div>
          </div>
          <div class="podium-base second"></div>
        </div>

        <!-- 1st Place -->
        <div v-if="salesByPathfinder[0]" class="podium-item first-place">
          <div class="podium-medal">
            <i class="pi pi-crown trophy-gold"></i>
            <span class="position-number">1</span>
          </div>
          <div class="podium-info">
            <h3>{{ salesByPathfinder[0].pathfinder.Name }}</h3>
            <div class="amount">{{ formatCurrency(salesByPathfinder[0].totalAmount) }}</div>
            <div class="products">{{ salesByPathfinder[0].totalQuantity }} produtos</div>
          </div>
          <div class="podium-base first"></div>
        </div>

        <!-- 3rd Place -->
        <div v-if="salesByPathfinder[2]" class="podium-item third-place">
          <div class="podium-medal">
            <i class="pi pi-trophy trophy-bronze"></i>
            <span class="position-number">3</span>
          </div>
          <div class="podium-info">
            <h5>{{ salesByPathfinder[2].pathfinder.Name }}</h5>
            <div class="amount">{{ formatCurrency(salesByPathfinder[2].totalAmount) }}</div>
            <div class="products">{{ salesByPathfinder[2].totalQuantity }} produtos</div>
          </div>
          <div class="podium-base third"></div>
        </div>
      </div>
    </div>

    <!-- Complete Ranking Table -->
    <div class="ranking-section">
      <div class="content-card">
        <h3>Ranking Completo</h3>
        <DataTable
          :value="salesByPathfinder"
          :paginator="true"
          :rows="10"
          class="p-datatable-gridlines"
          sortField="totalAmount"
          :sortOrder="-1"
        >
          <Column field="rank" header="Posição" style="width: 8rem">
            <template #body="{ index }">
              <div class="rank-cell">
                <Badge :value="index + 1" :severity="getRankSeverity(index)" />
                <i v-if="index < 3" :class="getRankIcon(index)" :style="getRankColor(index)"></i>
              </div>
            </template>
          </Column>

          <Column field="pathfinder.Name" header="Desbravador" sortable>
            <template #body="{ data }">
              <div class="pathfinder-cell">
                <Avatar
                  :label="data.pathfinder.Name.charAt(0)"
                  shape="circle"
                  :style="{ backgroundColor: getAvatarColor(data.pathfinder.Name) }"
                />
                <div class="pathfinder-info">
                  <div class="name">{{ data.pathfinder.Name }}</div>
                  <div v-if="data.pathfinder.Email" class="email">{{ data.pathfinder.Email }}</div>
                </div>
              </div>
            </template>
          </Column>

          <Column field="totalAmount" header="Total de Vendas" sortable>
            <template #body="{ data }">
              <div class="amount-cell">
                {{ formatCurrency(data.totalAmount) }}
              </div>
            </template>
          </Column>

          <Column field="totalQuantity" header="Produtos Vendidos" sortable>
            <template #body="{ data }">
              <Tag :value="data.totalQuantity" severity="info" />
            </template>
          </Column>

          <Column field="orderCount" header="Nº de Pedidos" sortable>
            <template #body="{ data }">
              <Tag :value="data.orderCount" severity="secondary" />
            </template>
          </Column>

          <Column field="averageSale" header="Média por Pedido" sortable>
            <template #body="{ data }">
              {{ formatCurrency(data.totalAmount / data.orderCount) }}
            </template>
          </Column>

          <Column header="Detalhes" style="width: 4rem">
            <template #body="{ data }">
              <Button
                icon="pi pi-eye"
                class="p-button-rounded p-button-outlined p-button-sm"
                @click="showPathfinderDetails(data)"
              />
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Statistics Cards -->
    <div class="stats-grid">
      <div class="stat-card">
        <i class="pi pi-users"></i>
        <h4>{{ salesByPathfinder.length }}</h4>
        <p>Desbravadores Vendendo</p>
      </div>

      <div class="stat-card">
        <i class="pi pi-dollar"></i>
        <h4>{{ formatCurrency(totalSales) }}</h4>
        <p>Total Arrecadado</p>
      </div>

      <div class="stat-card">
        <i class="pi pi-shopping-cart"></i>
        <h4>{{ totalProductsSold }}</h4>
        <p>Produtos Vendidos</p>
      </div>

      <div class="stat-card">
        <i class="pi pi-chart-line"></i>
        <h4>{{ formatCurrency(averageSalePerPathfinder) }}</h4>
        <p>Média por Desbravador</p>
      </div>
    </div>

    <!-- Pathfinder Details Dialog -->
    <Dialog
      v-model:visible="showDetailsDialog"
      :header="`Detalhes - ${selectedPathfinder?.pathfinder?.Name || ''}`"
      :modal="true"
      style="width: 600px"
    >
      <div v-if="selectedPathfinder" class="details-content">
        <div class="details-grid">
          <div class="detail-item">
            <h6>Total de Vendas</h6>
            <div class="detail-value">{{ formatCurrency(selectedPathfinder.totalAmount) }}</div>
          </div>
          <div class="detail-item">
            <h6>Produtos Vendidos</h6>
            <div class="detail-value">{{ selectedPathfinder.totalQuantity }}</div>
          </div>
          <div class="detail-item">
            <h6>Número de Pedidos</h6>
            <div class="detail-value">{{ selectedPathfinder.orderCount }}</div>
          </div>
          <div class="detail-item">
            <h6>Ticket Médio</h6>
            <div class="detail-value">{{ formatCurrency(selectedPathfinder.totalAmount / selectedPathfinder.orderCount) }}</div>
          </div>
        </div>

        <Divider />

        <h6>Histórico de Pedidos</h6>
        <DataTable :value="pathfinderSales" class="p-datatable-sm">
          <Column field="Date" header="Data">
            <template #body="{ data }">
              {{ formatDate(data.Date) }}
            </template>
          </Column>
          <Column field="productName" header="Itens"></Column>
          <Column field="Quantity" header="Qtd Total"></Column>
          <Column field="PaymentMethod" header="Pagamento">
            <template #body="{ data }">
              <Tag
                :value="getPaymentMethodLabel(data.PaymentMethod)"
                :severity="getPaymentMethodSeverity(data.PaymentMethod)"
              />
            </template>
          </Column>
          <Column field="TotalAmount" header="Valor">
            <template #body="{ data }">
              {{ formatCurrency(data.TotalAmount) }}
            </template>
          </Column>
        </DataTable>
      </div>

      <template #footer>
        <Button label="Fechar" icon="pi pi-times" @click="showDetailsDialog = false" />
      </template>
    </Dialog>

    <Toast />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'
import type { PathfinderSalesData } from '@/stores/fundraiser'

// Store and utilities
const fundraiserStore = useFundraiserStore()
const toast = useToast()

// Component state
const showDetailsDialog = ref(false)
const selectedPathfinder = ref<PathfinderSalesData | null>(null)

// Computed properties
const salesByPathfinder = computed(() => fundraiserStore.salesByPathfinder)
const totalSales = computed(() => fundraiserStore.totalSales)

const totalProductsSold = computed(() => {
  // TODO: Calculate from OrderItemsTable when implemented
  return 0
})

const averageSalePerPathfinder = computed(() => {
  if (salesByPathfinder.value.length === 0) return 0
  return totalSales.value / salesByPathfinder.value.length
})

const pathfinderSales = computed(() => {
  if (!selectedPathfinder.value) return []

  return fundraiserStore.orders
    .filter(order => order.PathfinderId === selectedPathfinder.value!.pathfinder.PK)
    .map(order => {
      // TODO: Load items from OrderItemsTable
      const itemsText = 'N/A'

      return {
        PK: order.PK,
        Date: order.Date,
        productName: itemsText,
        Quantity: 0, // TODO: sum from items
        PaymentMethod: order.PaymentMethod,
        TotalAmount: order.TotalAmount,
        CreatedAt: order.CreatedAt
      }
    })
    .sort((a, b) => new Date(b.CreatedAt).getTime() - new Date(a.CreatedAt).getTime())
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

const getRankSeverity = (index: number) => {
  if (index === 0) return 'warning' // Gold
  if (index === 1) return 'secondary' // Silver
  if (index === 2) return 'info' // Bronze
  return 'primary'
}

const getRankIcon = (index: number) => {
  if (index === 0) return 'pi pi-crown'
  if (index === 1) return 'pi pi-trophy'
  if (index === 2) return 'pi pi-trophy'
  return ''
}

const getRankColor = (index: number) => {
  if (index === 0) return { color: '#FFD700' } // Gold
  if (index === 1) return { color: '#C0C0C0' } // Silver
  if (index === 2) return { color: '#CD7F32' } // Bronze
  return {}
}

const getAvatarColor = (name: string) => {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8']
  const index = name.charCodeAt(0) % colors.length
  return colors[index]
}

const getPaymentMethodLabel = (method: string) => {
  const labels: Record<string, string> = {
    'card': 'Cartão',
    'cash': 'Dinheiro',
    'pix-church': 'Pix Igreja',
    'pix-qr': 'Pix QR'
  }
  return labels[method] || method
}

const getPaymentMethodSeverity = (method: string) => {
  const severities: Record<string, string> = {
    'card': 'info',
    'cash': 'success',
    'pix-church': 'warning',
    'pix-qr': 'secondary'
  }
  return severities[method] || 'primary'
}

const showPathfinderDetails = (pathfinderData: PathfinderSalesData) => {
  selectedPathfinder.value = pathfinderData
  showDetailsDialog.value = true
}

const exportRanking = () => {
  try {
    const headers = ['Posição', 'Nome', 'Total de Vendas', 'Produtos Vendidos', 'Número de Pedidos', 'Ticket Médio']
    const rows = salesByPathfinder.value.map((data, index) => [
      index + 1,
      data.pathfinder.Name,
      `R$ ${data.totalAmount.toFixed(2).replace('.', ',')}`,
      data.totalQuantity,
      data.orderCount,
      `R$ ${(data.totalAmount / data.orderCount).toFixed(2).replace('.', ',')}`
    ])

    const csvContent = [headers, ...rows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `ranking_desbravadores_${new Date().toISOString().split('T')[0]}.csv`
    link.click()

    toast.add({
      severity: 'success',
      summary: 'Sucesso',
      detail: 'Ranking exportado com sucesso!',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Erro',
      detail: 'Erro ao exportar ranking',
      life: 3000
    })
  }
}
</script>

<style scoped>
.leaderboard {
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

.podium-section {
  margin-bottom: 3rem;
}

.podium-container {
  display: flex;
  justify-content: center;
  align-items: flex-end;
  gap: 2rem;
  margin: 2rem 0;
}

.podium-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.podium-medal {
  position: relative;
  margin-bottom: 1rem;
}

.position-number {
  position: absolute;
  bottom: -5px;
  right: -5px;
  background: white;
  border: 2px solid #ddd;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: bold;
}

.trophy-gold {
  color: #FFD700;
  font-size: 3rem;
}

.trophy-silver {
  color: #C0C0C0;
  font-size: 2.5rem;
}

.trophy-bronze {
  color: #CD7F32;
  font-size: 2rem;
}

.podium-info {
  text-align: center;
  margin-bottom: 1rem;
  min-height: 80px;
}

.podium-info h3, .podium-info h4, .podium-info h5 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.podium-info .amount {
  font-size: 1.25rem;
  font-weight: bold;
  color: var(--primary-color);
  margin-bottom: 0.25rem;
}

.podium-info .products {
  font-size: 0.875rem;
  color: #6c757d;
}

.podium-base {
  width: 120px;
  border-radius: 8px 8px 0 0;
}

.podium-base.first {
  height: 100px;
  background: linear-gradient(135deg, #FFD700, #FFA500);
}

.podium-base.second {
  height: 80px;
  background: linear-gradient(135deg, #C0C0C0, #A0A0A0);
}

.podium-base.third {
  height: 60px;
  background: linear-gradient(135deg, #CD7F32, #B8860B);
}

.ranking-section {
  margin-bottom: 2rem;
}

.content-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.content-card h3 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
}

.rank-cell {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.pathfinder-cell {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.pathfinder-info .name {
  font-weight: 500;
}

.pathfinder-info .email {
  font-size: 0.875rem;
  color: #6c757d;
}

.amount-cell {
  text-align: right;
  font-weight: bold;
  font-size: 1.125rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.stat-card i {
  font-size: 2rem;
  margin-bottom: 0.5rem;
  display: block;
}

.stat-card h4 {
  margin: 0.5rem 0;
  color: #2c3e50;
}

.stat-card p {
  margin: 0;
  color: #6c757d;
  font-size: 0.875rem;
}

.details-content {
  padding: 1rem 0;
}

.details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
  margin-bottom: 1rem;
}

.detail-item h6 {
  color: #6c757d;
  margin: 0 0 0.5rem 0;
  font-size: 0.875rem;
}

.detail-value {
  font-size: 1.25rem;
  font-weight: bold;
  color: #2c3e50;
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

  .podium-container {
    flex-direction: column;
    align-items: center;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .details-grid {
    grid-template-columns: 1fr;
  }
}
</style>