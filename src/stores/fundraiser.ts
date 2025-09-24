import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Pathfinder {
  PK: string // PATHFINDER#<uuid>
  SK: string
  Name: string
  CreatedAt: string
}

export interface Product {
  PK: string // PRODUCT#<uuid>
  SK: string
  Name: string
  Price: number
  Category: 'pizza' | 'pastry' | 'ice-cream' | 'beverage' | 'combo' | 'other'
  Flavors?: string[]
  CreatedAt: string
}

export interface PriceHistory {
  PK: string // PRICEHISTORY#<uuid>
  SK: string
  ProductId: string // PRODUCT#<uuid>
  OrderId?: string // ORDER#<uuid>
  Price: number
  EffectiveDate: string
  Notes?: string
  CreatedAt: string
}

export interface OrderItem {
  PK: string // ORDERITEM#<uuid>
  SK: string
  OrderId: string // ORDER#<uuid>
  ProductId: string // PRODUCT#<uuid>
  Quantity: number
  Flavor?: string
  UnitPrice: number
  TotalPrice: number
  CreatedAt: string
}

export interface Order {
  PK: string // ORDER#<uuid>
  SK: string
  UserId?: string
  PathfinderId: string // PATHFINDER#<uuid>
  CustomerName: string
  Subtotal: number
  Discount: number
  TotalAmount: number
  PaymentMethod: 'card' | 'cash' | 'pix-church' | 'pix-qr'
  Status: 'pending' | 'preparing' | 'ready' | 'delivered'
  Date: string
  Notes?: string
  CreatedAt: string
}

export interface PathfinderSalesData {
  pathfinder: Pathfinder
  totalAmount: number
  totalQuantity: number
  orderCount: number
}

export interface ProductSalesData {
  product: Product
  totalQuantity: number
  totalAmount: number
  orderCount: number
}

export interface OrderItemWithDetails {
  ProductId: string
  Quantity: number
  Flavor?: string
  productName: string
  TotalPrice: number
}

export const useFundraiserStore = defineStore('fundraiser', () => {
  // State
  const pathfinders = ref<Pathfinder[]>([])
  const orders = ref<Order[]>([])
  const products = ref<Product[]>([])

  // Load data from Supabase
  const loadFromSupabase = async () => {
    try {
      // Load pathfinders
      const { data: pathfindersData, error: pathfindersError } = await supabase
        .from('PathfindersTable')
        .select('*')

      if (pathfindersError) throw pathfindersError
      pathfinders.value = pathfindersData || []

      // Load products
      const { data: productsData, error: productsError } = await supabase
        .from('ProductsTable')
        .select('*')

      if (productsError) throw productsError
      products.value = productsData || []

      // Load orders
      const { data: ordersData, error: ordersError } = await supabase
        .from('OrdersTable')
        .select('*')

      if (ordersError) throw ordersError
      orders.value = ordersData || []
    } catch (error) {
      console.error('Error loading data from Supabase:', error)
    }
  }

  // Pathfinder management
  const addPathfinder = async (pathfinder: Omit<Pathfinder, 'PK' | 'SK' | 'CreatedAt'>) => {
    try {
      const { data, error } = await supabase
        .from('PathfindersTable')
        .insert([{ Name: pathfinder.Name }])
        .select()
        .single()

      if (error) throw error

      pathfinders.value.push(data)
      return data
    } catch (error) {
      console.error('Error adding pathfinder:', error)
      throw error
    }
  }

  const updatePathfinder = async (pk: string, updatedData: Partial<Pathfinder>) => {
    try {
      const { data, error } = await supabase
        .from('PathfindersTable')
        .update(updatedData)
        .eq('PK', pk)
        .select()
        .single()

      if (error) throw error

      const index = pathfinders.value.findIndex(p => p.PK === pk)
      if (index !== -1) {
        pathfinders.value[index] = data
      }
    } catch (error) {
      console.error('Error updating pathfinder:', error)
      throw error
    }
  }

  const deletePathfinder = async (pk: string) => {
    try {
      const { error } = await supabase
        .from('PathfindersTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      pathfinders.value = pathfinders.value.filter(p => p.PK !== pk)
      // Orders will be cascade deleted by database
      orders.value = orders.value.filter(o => o.PathfinderId !== pk)
    } catch (error) {
      console.error('Error deleting pathfinder:', error)
      throw error
    }
  }

  // Product management
  const addProduct = async (product: Omit<Product, 'PK' | 'SK' | 'CreatedAt'>) => {
    try {
      const { data, error } = await supabase
        .from('ProductsTable')
        .insert([product])
        .select()
        .single()

      if (error) throw error

      products.value.push(data)
      return data
    } catch (error) {
      console.error('Error adding product:', error)
      throw error
    }
  }

  const updateProduct = async (pk: string, updatedData: Partial<Product>, priceNote?: string) => {
    try {
      const oldProduct = products.value.find(p => p.PK === pk)

      const { data, error } = await supabase
        .from('ProductsTable')
        .update(updatedData)
        .eq('PK', pk)
        .select()
        .single()

      if (error) throw error

      if (oldProduct && updatedData.Price && oldProduct.Price !== updatedData.Price) {
        await supabase
          .from('PriceHistoryTable')
          .insert([{
            ProductId: pk,
            Price: updatedData.Price,
            Notes: priceNote || 'Price updated',
            EffectiveDate: new Date().toISOString()
          }])
      }

      const index = products.value.findIndex(p => p.PK === pk)
      if (index !== -1) {
        products.value[index] = data
      }
    } catch (error) {
      console.error('Error updating product:', error)
      throw error
    }
  }

  const getPriceHistory = async (productId: string): Promise<PriceHistory[]> => {
    try {
      const { data, error } = await supabase
        .from('PriceHistoryTable')
        .select('*')
        .eq('ProductId', productId)
        .order('EffectiveDate', { ascending: false })

      if (error) throw error

      return data || []
    } catch (error) {
      console.error('Error getting price history:', error)
      return []
    }
  }

  const deleteProduct = async (pk: string) => {
    try {
      const { error } = await supabase
        .from('ProductsTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      products.value = products.value.filter(p => p.PK !== pk)
    } catch (error) {
      console.error('Error deleting product:', error)
      throw error
    }
  }

  // Order management
  const addOrder = async (order: Omit<Order, 'PK' | 'SK' | 'CreatedAt'>) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()

      const { data, error } = await supabase
        .from('OrdersTable')
        .insert([{
          UserId: user?.id,
          PathfinderId: order.PathfinderId,
          CustomerName: order.CustomerName,
          Subtotal: order.Subtotal,
          Discount: order.Discount,
          TotalAmount: order.TotalAmount,
          PaymentMethod: order.PaymentMethod,
          Status: order.Status || 'pending',
          Date: order.Date || new Date().toISOString().split('T')[0],
          Notes: order.Notes
        }])
        .select()
        .single()

      if (error) throw error

      orders.value.push(data)
      return data
    } catch (error) {
      console.error('Error adding order:', error)
      throw error
    }
  }

  const updateOrder = async (pk: string, updatedData: Partial<Order>) => {
    try {
      const { data, error } = await supabase
        .from('OrdersTable')
        .update(updatedData)
        .eq('PK', pk)
        .select()
        .single()

      if (error) throw error

      const index = orders.value.findIndex(o => o.PK === pk)
      if (index !== -1) {
        orders.value[index] = data
      }
    } catch (error) {
      console.error('Error updating order:', error)
      throw error
    }
  }

  const updateOrderStatus = async (pk: string, status: Order['Status']) => {
    await updateOrder(pk, { Status: status })
  }

  const deleteOrder = async (pk: string) => {
    try {
      const { error } = await supabase
        .from('OrdersTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      orders.value = orders.value.filter(o => o.PK !== pk)
    } catch (error) {
      console.error('Error deleting order:', error)
      throw error
    }
  }

  // Computed properties for statistics
  const totalSales = computed(() => {
    return orders.value.reduce((total, order) => total + order.TotalAmount, 0)
  })

  const totalOrders = computed(() => orders.value.length)

  const ordersByStatus = computed(() => {
    return {
      pending: orders.value.filter(o => o.Status === 'pending').length,
      preparing: orders.value.filter(o => o.Status === 'preparing').length,
      ready: orders.value.filter(o => o.Status === 'ready').length,
      delivered: orders.value.filter(o => o.Status === 'delivered').length
    }
  })

  const salesByPathfinder = computed((): PathfinderSalesData[] => {
    const salesMap = new Map<string, PathfinderSalesData>()

    orders.value.forEach(order => {
      const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)
      if (pathfinder) {
        const existing = salesMap.get(order.PathfinderId) || {
          pathfinder,
          totalAmount: 0,
          totalQuantity: 0,
          orderCount: 0
        }

        existing.totalAmount += order.TotalAmount
        // Note: We'll need to load order items separately or join them
        existing.totalQuantity += 0 // TODO: Load from OrderItemsTable
        existing.orderCount += 1

        salesMap.set(order.PathfinderId, existing)
      }
    })

    return Array.from(salesMap.values()).sort((a, b) => b.totalAmount - a.totalAmount)
  })

  const salesByProduct = computed((): ProductSalesData[] => {
    // TODO: This needs to load from OrderItemsTable
    return []
  })

  const salesByPaymentMethod = computed(() => {
    const paymentMap = { card: 0, cash: 0, 'pix-church': 0, 'pix-qr': 0 }

    orders.value.forEach(order => {
      paymentMap[order.PaymentMethod] += order.TotalAmount
    })

    return paymentMap
  })

  const topPathfinder = computed((): PathfinderSalesData | null => {
    return salesByPathfinder.value[0] || null
  })

  const recentOrders = computed(() => {
    return orders.value
      .map(order => {
        const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)
        return {
          ...order,
          pathfinderName: pathfinder?.Name || 'N/A'
        }
      })
      .sort((a, b) => new Date(b.CreatedAt).getTime() - new Date(a.CreatedAt).getTime())
      .slice(0, 10)
  })

  const ordersWithDetails = computed(() => {
    return orders.value.map(order => {
      const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)
      return {
        ...order,
        pathfinderName: pathfinder?.Name || 'N/A',
        itemsWithDetails: [] as OrderItemWithDetails[]
      }
    })
  })

  const kitchenOrders = computed(() => {
    return ordersWithDetails.value
      .filter(order => ['pending', 'preparing', 'ready'].includes(order.Status))
      .sort((a, b) => new Date(a.CreatedAt).getTime() - new Date(b.CreatedAt).getTime())
  })

  // Export data for spreadsheet
  const exportToCSV = () => {
    const headers = ['Data', 'Pedido #', 'Desbravador', 'Cliente', 'Subtotal', 'Desconto', 'Total', 'Forma de Pagamento', 'Status']
    const rows = orders.value.map(order => {
      const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)

      const paymentText = {
        'card': 'Cartão',
        'cash': 'Dinheiro',
        'pix-church': 'Pix Igreja',
        'pix-qr': 'Pix QR'
      }[order.PaymentMethod] || order.PaymentMethod

      return [
        order.Date,
        order.PK,
        pathfinder?.Name || 'N/A',
        order.CustomerName,
        `R$ ${order.Subtotal.toFixed(2).replace('.', ',')}`,
        `R$ ${order.Discount.toFixed(2).replace('.', ',')}`,
        `R$ ${order.TotalAmount.toFixed(2).replace('.', ',')}`,
        paymentText,
        order.Status
      ]
    })

    const csvContent = [headers, ...rows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `pedidos_desbravadores_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
  }

  // Initialize store
  loadFromSupabase()

  return {
    // State
    pathfinders,
    orders,
    products,

    // Actions
    addPathfinder,
    updatePathfinder,
    deletePathfinder,
    addProduct,
    updateProduct,
    deleteProduct,
    getPriceHistory,
    addOrder,
    updateOrder,
    updateOrderStatus,
    deleteOrder,
    loadFromSupabase,
    exportToCSV,

    // Computed
    totalSales,
    totalOrders,
    ordersByStatus,
    salesByPathfinder,
    salesByProduct,
    salesByPaymentMethod,
    topPathfinder,
    recentOrders,
    ordersWithDetails,
    kitchenOrders
  }
})