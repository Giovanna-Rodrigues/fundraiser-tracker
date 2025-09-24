<template>
  <div class="dashboard">
    <!-- Header with Club Logo -->
    <div class="header-section">
      <div class="club-header">
        <img src="/logo.jpeg" alt="Logo do Clube" class="club-logo" />
        <div class="club-info">
          <h1>Campanha de Arrecadação</h1>
          <p>Mini Pizzas e Pastéis - Clube de Desbravadores</p>
        </div>
      </div>
    </div>

    <!-- Key Metrics Cards -->
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Vendas Total</span>
            <div class="metric-value">{{ formatCurrency(totalSales) }}</div>
          </div>
          <div class="metric-icon bg-blue">
            <i class="pi pi-dollar"></i>
          </div>
        </div>
        <div class="metric-footer">
          <span class="success">{{ totalSalesCount }} vendas</span>
          <span class="muted"> realizadas</span>
        </div>
      </div>

      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Desbravadores Ativos</span>
            <div class="metric-value">{{ activePathfindersCount }}</div>
          </div>
          <div class="metric-icon bg-orange">
            <i class="pi pi-users"></i>
          </div>
        </div>
        <div class="metric-footer">
          <span class="success">{{ totalPathfindersCount }} cadastrados</span>
        </div>
      </div>

      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Produtos Vendidos</span>
            <div class="metric-value">{{ totalProductsSold }}</div>
          </div>
          <div class="metric-icon bg-cyan">
            <i class="pi pi-shopping-cart"></i>
          </div>
        </div>
        <div class="metric-footer">
          <span class="muted">unidades</span>
        </div>
      </div>

      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Líder do Mês</span>
            <div class="metric-value">{{ topPathfinderName || 'N/A' }}</div>
          </div>
          <div class="metric-icon bg-purple">
            <i class="pi pi-trophy"></i>
          </div>
        </div>
        <div class="metric-footer">
          <span class="success">{{ formatCurrency(topPathfinderSales) }}</span>
          <span class="muted"> em vendas</span>
        </div>
      </div>
    </div>

    <!-- Charts Section -->
    <div class="charts-grid">
      <div class="chart-card">
        <h3>Vendas por Forma de Pagamento</h3>
        <Chart type="doughnut" :data="paymentMethodChartData" :options="chartOptions" />
      </div>

      <div class="chart-card">
        <h3>Produtos Mais Vendidos</h3>
        <Chart type="bar" :data="productSalesChartData" :options="barChartOptions" />
      </div>
    </div>

    <!-- Content Grid -->
    <div class="content-grid">
      <!-- Top Performers -->
      <div class="content-card large">
        <div class="card-header">
          <h3>Top 5 Desbravadores</h3>
          <Button
            label="Ver Ranking Completo"
            icon="pi pi-external-link"
            class="p-button-outlined"
            @click="$router.push('/leaderboard')"
          />
        </div>
        <DataTable :value="topPathfinders" class="p-datatable-sm">
          <Column field="rank" header="#" style="width: 3rem">
            <template #body="{ index }">
              <Badge :value="index + 1" :severity="getRankSeverity(index)" />
            </template>
          </Column>
          <Column field="pathfinder.Name" header="Nome"></Column>
          <Column field="totalAmount" header="Total de Vendas">
            <template #body="{ data }">
              {{ formatCurrency(data.totalAmount) }}
            </template>
          </Column>
          <Column field="totalQuantity" header="Qtd. Produtos"></Column>
          <Column field="orderCount" header="Nº Vendas"></Column>
        </DataTable>
      </div>

      <!-- Quick Actions -->
      <div class="content-card">
        <h3>Ações Rápidas</h3>
        <div class="actions-grid">
          <Button
            label="Novo Pedido"
            icon="pi pi-plus"
            class="p-button-success action-btn"
            @click="$router.push('/orders')"
          />
          <Button
            label="Gerenciar Desbravadores"
            icon="pi pi-users"
            class="p-button-outlined action-btn"
            @click="$router.push('/pathfinders')"
          />
          <Button
            label="Exportar Relatório"
            icon="pi pi-download"
            class="p-button-outlined action-btn"
            @click="exportData"
          />
          <Button
            label="Ver Todas as Vendas"
            icon="pi pi-list"
            class="p-button-outlined action-btn"
            @click="$router.push('/sales-list')"
          />
        </div>
      </div>
    </div>

    <!-- Recent Sales -->
    <div class="content-card">
      <h3>Vendas Recentes</h3>
      <DataTable :value="recentSales" :paginator="true" :rows="5" class="p-datatable-sm">
        <Column field="Date" header="Data" sortable>
          <template #body="{ data }">
            {{ formatDate(data.Date) }}
          </template>
        </Column>
        <Column field="pathfinderName" header="Desbravador"></Column>
        <Column field="productName" header="Produto"></Column>
        <Column field="Quantity" header="Quantidade"></Column>
        <Column field="PaymentMethod" header="Pagamento">
          <template #body="{ data }">
            <Tag
              :value="data.PaymentMethod === 'card' ? 'Cartão' : 'Pix'"
              :severity="data.PaymentMethod === 'card' ? 'info' : 'success'"
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

    <Toast />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFundraiserStore } from '@/stores/fundraiser'
import { useToast } from 'primevue/usetoast'

// Store and utilities
const fundraiserStore = useFundraiserStore()
const toast = useToast()

// Computed properties for metrics
const totalSales = computed(() => fundraiserStore.totalSales)
const totalSalesCount = computed(() => fundraiserStore.totalOrders)
const totalPathfindersCount = computed(() => fundraiserStore.pathfinders.length)

const activePathfindersCount = computed(() => {
  const pathfindersWithOrders = new Set(fundraiserStore.orders.map(order => order.PathfinderId))
  return pathfindersWithOrders.size
})

const totalProductsSold = computed(() => {
  // TODO: Calculate from OrderItemsTable when implemented
  return 0
})

const topPathfinderName = computed(() => {
  return fundraiserStore.topPathfinder?.pathfinder?.Name || 'N/A'
})

const topPathfinderSales = computed(() => {
  return fundraiserStore.topPathfinder?.totalAmount || 0
})

const topPathfinders = computed(() => {
  return fundraiserStore.salesByPathfinder.slice(0, 5)
})

const recentSales = computed(() => {
  return fundraiserStore.recentOrders.slice(0, 10)
})

// Chart data
const paymentMethodChartData = computed(() => {
  const paymentData = fundraiserStore.salesByPaymentMethod
  return {
    labels: ['Cartão', 'Dinheiro', 'Pix Igreja', 'Pix QR'],
    datasets: [
      {
        data: [paymentData.card, paymentData.cash, paymentData['pix-church'], paymentData['pix-qr']],
        backgroundColor: ['#42A5F5', '#66BB6A', '#FFA726', '#AB47BC'],
        hoverBackgroundColor: ['#64B5F6', '#81C784', '#FFB74D', '#BA68C8']
      }
    ]
  }
})

const productSalesChartData = computed(() => {
  const productData = fundraiserStore.salesByProduct
  return {
    labels: productData.map(item => item.product.Name),
    datasets: [
      {
        label: 'Quantidade Vendida',
        backgroundColor: '#42A5F5',
        data: productData.map(item => item.totalQuantity)
      }
    ]
  }
})

// Chart options
const chartOptions = ref({
  plugins: {
    legend: {
      labels: {
        usePointStyle: true
      }
    }
  },
  responsive: true,
  maintainAspectRatio: false
})

const barChartOptions = ref({
  plugins: {
    legend: {
      display: false
    }
  },
  scales: {
    y: {
      beginAtZero: true
    }
  },
  responsive: true,
  maintainAspectRatio: false
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
.dashboard {
  padding: 1rem;
  width: 100%;
  overflow-x: hidden;
}

.header-section {
  margin-bottom: 2rem;
}

.club-header {
  display: flex;
  align-items: center;
  gap: 2rem;
  padding: 2rem;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 1rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.club-logo {
  height: 100px;
  width: 100px;
  object-fit: cover;
  border-radius: 50%;
  border: 4px solid white;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.club-info h1 {
  margin: 0;
  color: #2c3e50;
  font-size: 2.5rem;
  font-weight: bold;
}

.club-info p {
  margin: 0.5rem 0 0 0;
  color: #6c757d;
  font-size: 1.2rem;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.metric-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.metric-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.metric-label {
  color: #6c757d;
  font-size: 0.875rem;
  font-weight: 500;
  display: block;
  margin-bottom: 0.5rem;
}

.metric-value {
  color: #2c3e50;
  font-size: 1.5rem;
  font-weight: bold;
}

.metric-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 1.25rem;
}

.bg-blue { background-color: #3b82f6; }
.bg-orange { background-color: #f97316; }
.bg-cyan { background-color: #06b6d4; }
.bg-purple { background-color: #8b5cf6; }

.metric-footer .success {
  color: #10b981;
  font-weight: 500;
}

.metric-footer .muted {
  color: #6c757d;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.chart-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.chart-card h3 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
  font-size: 1.25rem;
}

.content-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 1rem;
  margin-bottom: 2rem;
}

@media (max-width: 1024px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .charts-grid {
    grid-template-columns: 1fr;
  }
}

.content-card {
  background: white;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border: 1px solid #e9ecef;
}

.content-card.large {
  grid-column: span 1;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.card-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.25rem;
}

.actions-grid {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.action-btn {
  width: 100%;
}

@media (max-width: 768px) {
  .dashboard {
    padding: 0.5rem;
  }

  .club-header {
    flex-direction: column;
    text-align: center;
    padding: 1.5rem;
    gap: 1rem;
  }

  .club-logo {
    height: 80px;
    width: 80px;
  }

  .club-info h1 {
    font-size: 1.75rem;
  }

  .club-info p {
    font-size: 1rem;
  }

  .content-grid {
    grid-template-columns: 1fr;
  }

  .charts-grid {
    grid-template-columns: 1fr;
  }

  .metrics-grid {
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  }

  .metric-card {
    padding: 1rem;
  }

  .chart-card, .content-card {
    padding: 1rem;
  }
}

@media (max-width: 480px) {
  .dashboard {
    padding: 0.25rem;
  }

  .club-header {
    padding: 1rem;
  }

  .club-logo {
    height: 60px;
    width: 60px;
  }

  .club-info h1 {
    font-size: 1.5rem;
  }

  .metrics-grid {
    grid-template-columns: 1fr;
  }

  .metric-card, .chart-card, .content-card {
    padding: 0.75rem;
  }

  .metric-value {
    font-size: 1.25rem;
  }

  .actions-grid {
    gap: 0.5rem;
  }
}
</style>