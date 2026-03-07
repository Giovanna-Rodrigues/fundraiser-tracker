import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Pathfinder {
  PK: string // PATHFINDER#<uuid>
  SK: string
  Name: string
  Type: 'desbravador' | 'staff' | 'directors'
  Email?: string
  Phone?: string
  ParentName?: string
  ParentEmail?: string
  ParentPhone?: string
  BirthDate?: string
  Address?: string
  Notes?: string
  IsActive: boolean
  RegistrationYear?: number
  Documents: DocumentStatusMap
  CreatedAt: string
  UpdatedAt: string
}

export interface DocumentStatus {
  status: 'received' | 'missing'
  updatedAt?: string
  updatedBy?: string
  expiryDate?: string // For criminal background checks
  notes?: string
}

export interface DocumentStatusMap {
  id_cpf?: DocumentStatus
  sus_card?: DocumentStatus
  proof_residence?: DocumentStatus
  parent_id_cpf?: DocumentStatus
  vaccination_card?: DocumentStatus
  criminal_background?: DocumentStatus
  health_insurance?: DocumentStatus
}

export interface FeeType {
  PK: string // FEETYPE#<uuid>
  SK: string
  Name: string
  Description?: string
  Amount: number
  FeeCategory: 'membership' | 'monthly' | 'event' | 'equipment' | 'other'
  RecurrenceType?: 'one-time' | 'monthly' | 'annual'
  AppliesTo: ('desbravador' | 'staff' | 'directors')[]
  DueDate?: string
  IsActive: boolean
  Year?: number
  CreatedAt: string
  UpdatedAt: string
}

export interface PathfinderFee {
  PK: string // PATHFINDERFEE#<uuid>
  SK: string
  PathfinderId: string
  FeeTypeId: string
  Amount: number
  DueDate: string
  Status: 'pending' | 'partial' | 'paid' | 'overdue' | 'waived'
  AmountPaid: number
  AmountRemaining: number
  Notes?: string
  AssignedAt: string
  CreatedAt: string
  UpdatedAt: string
}

export interface Payment {
  PK: string // PAYMENT#<uuid>
  SK: string
  PathfinderId: string
  PathfinderFeeId: string
  Amount: number
  PaymentMethod: 'card' | 'cash' | 'pix-church' | 'pix-qr' | '7me' | 'church'
  PaymentDate: string
  ReceivedBy?: string
  Notes?: string
  ReceiptNumber?: string
  CreatedAt: string
}

export interface PathfinderFeeWithDetails extends PathfinderFee {
  feeType?: FeeType
  payments?: Payment[]
}

export interface PathfinderFinancialSummary {
  pathfinder: Pathfinder
  totalFeesAssigned: number
  totalAmountOwed: number
  totalAmountPaid: number
  totalAmountRemaining: number
  overdueFeesCount: number
  paidFeesCount: number
  totalPaymentsMade: number
  fees: PathfinderFeeWithDetails[]
}

export interface DocumentCompletionStatus {
  pathfinder: Pathfinder
  totalRequired: number
  totalReceived: number
  completionPercentage: number
  missingDocuments: string[]
}

export interface ComboItem {
  ProductId: string
  Quantity: number
  AllowFlavorSelection?: boolean
}

export interface Product {
  PK: string // PRODUCT#<uuid>
  SK: string
  Name: string
  Price: number
  Category: 'pizza' | 'pastry' | 'ice-cream' | 'beverage' | 'combo' | 'other'
  Flavors?: string[]
  Description?: string
  ComboItems?: ComboItem[]
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
  ComboFlavors?: string[]
  UnitPrice: number
  TotalPrice: number
  CreatedAt: string
}

export interface Campaign {
  PK: string // CAMPAIGN#<uuid>
  SK: string
  Name: string
  StartDate: string
  EndDate: string
  Status: 'planned' | 'active' | 'completed'
  Goal?: number
  Description?: string
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
  PaymentMethod?: 'card' | 'cash' | 'pix-church' | 'pix-qr' // null = pay later
  Status: 'pending' | 'preparing' | 'ready' | 'delivered' | 'not_picked_up'
  Date: string
  Notes?: string
  CampaignId?: string // CAMPAIGN#<uuid>
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
  const orderItems = ref<OrderItem[]>([])
  const campaigns = ref<Campaign[]>([])
  const selectedCampaignId = ref<string | null>(null)
  const feeTypes = ref<FeeType[]>([])
  const pathfinderFees = ref<PathfinderFee[]>([])
  const payments = ref<Payment[]>([])

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

      // Load order items
      const { data: orderItemsData, error: orderItemsError } = await supabase
        .from('OrderItemsTable')
        .select('*')

      if (orderItemsError) throw orderItemsError
      orderItems.value = orderItemsData || []

      // Load campaigns
      const { data: campaignsData, error: campaignsError } = await supabase
        .from('CampaignsTable')
        .select('*')
        .order('StartDate', { ascending: false })

      if (campaignsError) throw campaignsError
      campaigns.value = campaignsData || []

      // Set selected campaign to active campaign if available
      const activeCampaign = campaigns.value.find(c => c.Status === 'active')
      if (activeCampaign) {
        selectedCampaignId.value = activeCampaign.PK
      } else if (campaigns.value.length > 0) {
        selectedCampaignId.value = campaigns.value[0].PK
      }

      // Load fee types
      const { data: feeTypesData, error: feeTypesError } = await supabase
        .from('FeeTypesTable')
        .select('*')
        .order('CreatedAt', { ascending: false })

      if (feeTypesError) throw feeTypesError
      feeTypes.value = feeTypesData || []

      // Load pathfinder fees
      const { data: pathfinderFeesData, error: pathfinderFeesError } = await supabase
        .from('PathfinderFeesTable')
        .select('*')
        .order('CreatedAt', { ascending: false })

      if (pathfinderFeesError) throw pathfinderFeesError
      pathfinderFees.value = pathfinderFeesData || []

      // Load payments
      const { data: paymentsData, error: paymentsError } = await supabase
        .from('PaymentsTable')
        .select('*')
        .order('CreatedAt', { ascending: false })

      if (paymentsError) throw paymentsError
      payments.value = paymentsData || []
    } catch (error) {
      console.error('Error loading data from Supabase:', error)
    }
  }

  // Pathfinder management
  const addPathfinder = async (pathfinder: { Name: string } & Partial<Omit<Pathfinder, 'PK' | 'SK' | 'CreatedAt' | 'Name'>>) => {
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

  // Campaign management
  const addCampaign = async (campaign: Omit<Campaign, 'PK' | 'SK' | 'CreatedAt'>) => {
    try {
      // If this campaign is being set as active, deactivate all other campaigns
      if (campaign.Status === 'active') {
        await supabase
          .from('CampaignsTable')
          .update({ Status: 'completed' })
          .eq('Status', 'active')
      }

      const { data, error } = await supabase
        .from('CampaignsTable')
        .insert([campaign])
        .select()
        .single()

      if (error) throw error

      campaigns.value.unshift(data)

      // Set as selected campaign if active
      if (data.Status === 'active') {
        selectedCampaignId.value = data.PK
      }

      return data
    } catch (error) {
      console.error('Error adding campaign:', error)
      throw error
    }
  }

  const updateCampaign = async (pk: string, updatedData: Partial<Campaign>) => {
    try {
      // If updating to active status, deactivate all other campaigns
      if (updatedData.Status === 'active') {
        await supabase
          .from('CampaignsTable')
          .update({ Status: 'completed' })
          .eq('Status', 'active')
          .neq('PK', pk)
      }

      const { data, error } = await supabase
        .from('CampaignsTable')
        .update(updatedData)
        .eq('PK', pk)
        .select()
        .single()

      if (error) throw error

      const index = campaigns.value.findIndex(c => c.PK === pk)
      if (index !== -1) {
        campaigns.value[index] = data
      }

      // Update selected campaign if this became active
      if (data.Status === 'active') {
        selectedCampaignId.value = data.PK
      }
    } catch (error) {
      console.error('Error updating campaign:', error)
      throw error
    }
  }

  const deleteCampaign = async (pk: string) => {
    try {
      const { error } = await supabase
        .from('CampaignsTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      campaigns.value = campaigns.value.filter(c => c.PK !== pk)

      // If deleted campaign was selected, select another
      if (selectedCampaignId.value === pk) {
        const activeCampaign = campaigns.value.find(c => c.Status === 'active')
        selectedCampaignId.value = activeCampaign?.PK || campaigns.value[0]?.PK || null
      }
    } catch (error) {
      console.error('Error deleting campaign:', error)
      throw error
    }
  }

  const setSelectedCampaign = (campaignId: string | null) => {
    selectedCampaignId.value = campaignId
  }

  // Fee Type Management
  const addFeeType = async (feeType: Omit<FeeType, 'PK' | 'SK' | 'CreatedAt' | 'UpdatedAt'>) => {
    try {
      const { data, error } = await supabase
        .from('FeeTypesTable')
        .insert([feeType])
        .select()
        .single()

      if (error) throw error

      feeTypes.value.unshift(data)
      return data
    } catch (error) {
      console.error('Error adding fee type:', error)
      throw error
    }
  }

  const updateFeeType = async (pk: string, updatedData: Partial<FeeType>) => {
    try {
      const { data, error } = await supabase
        .from('FeeTypesTable')
        .update(updatedData)
        .eq('PK', pk)
        .select()
        .single()

      if (error) throw error

      const index = feeTypes.value.findIndex(f => f.PK === pk)
      if (index !== -1) {
        feeTypes.value[index] = data
      }
    } catch (error) {
      console.error('Error updating fee type:', error)
      throw error
    }
  }

  const deleteFeeType = async (pk: string) => {
    try {
      const { error } = await supabase
        .from('FeeTypesTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      feeTypes.value = feeTypes.value.filter(f => f.PK !== pk)
      // Cascade will delete associated PathfinderFees
      pathfinderFees.value = pathfinderFees.value.filter(pf => pf.FeeTypeId !== pk)
    } catch (error) {
      console.error('Error deleting fee type:', error)
      throw error
    }
  }

  // Pathfinder Fee Management
  const assignFeeToPathfinder = async (pathfinderId: string, feeTypeId: string, dueDate: string) => {
    try {
      const feeType = feeTypes.value.find(f => f.PK === feeTypeId)
      if (!feeType) throw new Error('Fee type not found')

      const { data, error } = await supabase
        .from('PathfinderFeesTable')
        .insert([{
          PathfinderId: pathfinderId,
          FeeTypeId: feeTypeId,
          Amount: feeType.Amount,
          DueDate: dueDate,
          Status: 'pending',
          AmountPaid: 0,
          AmountRemaining: feeType.Amount
        }])
        .select()
        .single()

      if (error) throw error

      pathfinderFees.value.unshift(data)
      return data
    } catch (error) {
      console.error('Error assigning fee to pathfinder:', error)
      throw error
    }
  }

  const bulkAssignFee = async (feeTypeId: string, pathfinderIds: string[], dueDate: string) => {
    try {
      const feeType = feeTypes.value.find(f => f.PK === feeTypeId)
      if (!feeType) throw new Error('Fee type not found')

      const feesToInsert = pathfinderIds.map(pathfinderId => ({
        PathfinderId: pathfinderId,
        FeeTypeId: feeTypeId,
        Amount: feeType.Amount,
        DueDate: dueDate,
        Status: 'pending',
        AmountPaid: 0,
        AmountRemaining: feeType.Amount
      }))

      const { data, error } = await supabase
        .from('PathfinderFeesTable')
        .insert(feesToInsert)
        .select()

      if (error) throw error

      pathfinderFees.value.unshift(...data)
      return data
    } catch (error) {
      console.error('Error bulk assigning fee:', error)
      throw error
    }
  }

  const updatePathfinderFee = async (pk: string, updatedData: Partial<PathfinderFee>) => {
    try {
      const { data, error } = await supabase
        .from('PathfinderFeesTable')
        .update(updatedData)
        .eq('PK', pk)
        .select()
        .single()

      if (error) throw error

      const index = pathfinderFees.value.findIndex(pf => pf.PK === pk)
      if (index !== -1) {
        pathfinderFees.value[index] = data
      }
    } catch (error) {
      console.error('Error updating pathfinder fee:', error)
      throw error
    }
  }

  const waiveFee = async (pk: string, notes?: string) => {
    await updatePathfinderFee(pk, { Status: 'waived', Notes: notes })
  }

  const deletePathfinderFee = async (pk: string) => {
    try {
      const { error } = await supabase
        .from('PathfinderFeesTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      pathfinderFees.value = pathfinderFees.value.filter(pf => pf.PK !== pk)
      // Cascade will delete associated payments
      payments.value = payments.value.filter(p => p.PathfinderFeeId !== pk)
    } catch (error) {
      console.error('Error deleting pathfinder fee:', error)
      throw error
    }
  }

  // Payment Management
  const addPayment = async (payment: Omit<Payment, 'PK' | 'SK' | 'CreatedAt' | 'ReceivedBy'>) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()

      const { data, error } = await supabase
        .from('PaymentsTable')
        .insert([{
          ...payment,
          ReceivedBy: user?.id
        }])
        .select()
        .single()

      if (error) throw error

      payments.value.unshift(data)

      // Reload pathfinder fees to get updated amounts (trigger updates them)
      const { data: updatedFee } = await supabase
        .from('PathfinderFeesTable')
        .select('*')
        .eq('PK', payment.PathfinderFeeId)
        .single()

      if (updatedFee) {
        const index = pathfinderFees.value.findIndex(pf => pf.PK === payment.PathfinderFeeId)
        if (index !== -1) {
          pathfinderFees.value[index] = updatedFee
        }
      }

      return data
    } catch (error) {
      console.error('Error adding payment:', error)
      throw error
    }
  }

  const deletePayment = async (pk: string) => {
    try {
      const payment = payments.value.find(p => p.PK === pk)
      if (!payment) throw new Error('Payment not found')

      const { error } = await supabase
        .from('PaymentsTable')
        .delete()
        .eq('PK', pk)

      if (error) throw error

      payments.value = payments.value.filter(p => p.PK !== pk)

      // Reload pathfinder fee to get updated amounts (trigger reverts them)
      const { data: updatedFee } = await supabase
        .from('PathfinderFeesTable')
        .select('*')
        .eq('PK', payment.PathfinderFeeId)
        .single()

      if (updatedFee) {
        const index = pathfinderFees.value.findIndex(pf => pf.PK === payment.PathfinderFeeId)
        if (index !== -1) {
          pathfinderFees.value[index] = updatedFee
        }
      }
    } catch (error) {
      console.error('Error deleting payment:', error)
      throw error
    }
  }

  // Document Management
  const getRequiredDocuments = (type: Pathfinder['Type']): string[] => {
    const common = ['id_cpf', 'sus_card', 'proof_residence']
    if (type === 'desbravador') {
      return [...common, 'parent_id_cpf', 'vaccination_card']
    } else if (type === 'staff' || type === 'directors') {
      return [...common, 'criminal_background']
    }
    return common
  }

  const updateDocumentStatus = async (
    pathfinderId: string,
    documentKey: keyof DocumentStatusMap,
    status: DocumentStatus
  ) => {
    try {
      const pathfinder = pathfinders.value.find(p => p.PK === pathfinderId)
      if (!pathfinder) throw new Error('Pathfinder not found')

      const { data: { user } } = await supabase.auth.getUser()

      const updatedDocuments = {
        ...pathfinder.Documents,
        [documentKey]: {
          ...status,
          updatedAt: new Date().toISOString(),
          updatedBy: user?.id
        }
      }

      const { data, error } = await supabase
        .from('PathfindersTable')
        .update({ Documents: updatedDocuments })
        .eq('PK', pathfinderId)
        .select()
        .single()

      if (error) throw error

      const index = pathfinders.value.findIndex(p => p.PK === pathfinderId)
      if (index !== -1) {
        pathfinders.value[index] = data
      }
    } catch (error) {
      console.error('Error updating document status:', error)
      throw error
    }
  }

  const bulkUpdateDocumentStatus = async (
    pathfinderIds: string[],
    documentKey: keyof DocumentStatusMap,
    status: DocumentStatus
  ) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()

      const promises = pathfinderIds.map(async (pathfinderId) => {
        const pathfinder = pathfinders.value.find(p => p.PK === pathfinderId)
        if (!pathfinder) return

        const updatedDocuments = {
          ...pathfinder.Documents,
          [documentKey]: {
            ...status,
            updatedAt: new Date().toISOString(),
            updatedBy: user?.id
          }
        }

        const { data, error } = await supabase
          .from('PathfindersTable')
          .update({ Documents: updatedDocuments })
          .eq('PK', pathfinderId)
          .select()
          .single()

        if (error) throw error

        const index = pathfinders.value.findIndex(p => p.PK === pathfinderId)
        if (index !== -1) {
          pathfinders.value[index] = data
        }
      })

      await Promise.all(promises)
    } catch (error) {
      console.error('Error bulk updating document status:', error)
      throw error
    }
  }

  // Order management
  const addOrder = async (order: Omit<Order, 'PK' | 'SK' | 'CreatedAt'> & { items?: any[] }) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()

      // Get active campaign or use provided CampaignId
      const campaignId = order.CampaignId || selectedCampaignId.value

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
          Notes: order.Notes,
          CampaignId: campaignId
        }])
        .select()
        .single()

      if (error) throw error

      orders.value.push(data)

      // Save order items if provided
      if (order.items && order.items.length > 0) {
        const itemsToInsert = order.items.map(item => ({
          OrderId: data.PK,
          ProductId: item.ProductId,
          Quantity: item.Quantity,
          Flavor: item.Flavor || null,
          UnitPrice: item.UnitPrice,
          TotalPrice: item.TotalPrice
        }))

        const { data: itemsData, error: itemsError } = await supabase
          .from('OrderItemsTable')
          .insert(itemsToInsert)
          .select()

        if (itemsError) throw itemsError

        orderItems.value.push(...itemsData)
      }

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
  const filteredOrders = computed(() => {
    if (!selectedCampaignId.value) return orders.value
    return orders.value.filter(o => o.CampaignId === selectedCampaignId.value)
  })

  const totalSales = computed(() => {
    return filteredOrders.value.reduce((total, order) => total + order.TotalAmount, 0)
  })

  const totalOrders = computed(() => filteredOrders.value.length)

  const totalProductsSold = computed(() => {
    const orderIds = new Set(filteredOrders.value.map(o => o.PK))
    return orderItems.value
      .filter(item => orderIds.has(item.OrderId))
      .reduce((sum, item) => sum + item.Quantity, 0)
  })

  const ordersByStatus = computed(() => {
    return {
      pending: filteredOrders.value.filter(o => o.Status === 'pending').length,
      preparing: filteredOrders.value.filter(o => o.Status === 'preparing').length,
      ready: filteredOrders.value.filter(o => o.Status === 'ready').length,
      delivered: filteredOrders.value.filter(o => o.Status === 'delivered').length,
      not_picked_up: filteredOrders.value.filter(o => o.Status === 'not_picked_up').length
    }
  })

  const salesByPathfinder = computed((): PathfinderSalesData[] => {
    const salesMap = new Map<string, PathfinderSalesData>()

    filteredOrders.value.forEach(order => {
      const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)
      if (pathfinder) {
        const existing = salesMap.get(order.PathfinderId) || {
          pathfinder,
          totalAmount: 0,
          totalQuantity: 0,
          orderCount: 0
        }

        existing.totalAmount += order.TotalAmount

        // Calculate total quantity from order items
        const orderItemsForThisOrder = orderItems.value.filter(item => item.OrderId === order.PK)
        const quantityForThisOrder = orderItemsForThisOrder.reduce((sum, item) => sum + item.Quantity, 0)
        existing.totalQuantity += quantityForThisOrder

        existing.orderCount += 1

        salesMap.set(order.PathfinderId, existing)
      }
    })

    return Array.from(salesMap.values()).sort((a, b) => b.totalAmount - a.totalAmount)
  })

  const salesByProduct = computed((): ProductSalesData[] => {
    const salesMap = new Map<string, ProductSalesData>()
    const orderIds = new Set(filteredOrders.value.map(o => o.PK))

    orderItems.value
      .filter(item => orderIds.has(item.OrderId))
      .forEach(item => {
        const product = products.value.find(p => p.PK === item.ProductId)
        if (product) {
          const existing = salesMap.get(item.ProductId) || {
            product,
            totalQuantity: 0,
            totalAmount: 0,
            orderCount: 0
          }

          existing.totalQuantity += item.Quantity
          existing.totalAmount += item.TotalPrice
          existing.orderCount += 1

          salesMap.set(item.ProductId, existing)
        }
      })

    return Array.from(salesMap.values()).sort((a, b) => b.totalQuantity - a.totalQuantity)
  })

  const salesByPaymentMethod = computed(() => {
    const paymentMap = { card: 0, cash: 0, 'pix-church': 0, 'pix-qr': 0 }

    filteredOrders.value.forEach(order => {
      if (order.PaymentMethod) {
        paymentMap[order.PaymentMethod] += order.TotalAmount
      }
    })

    return paymentMap
  })

  const topPathfinder = computed((): PathfinderSalesData | null => {
    return salesByPathfinder.value[0] || null
  })

  const recentOrders = computed(() => {
    return filteredOrders.value
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

      // Get order items for this order
      const orderItemsForOrder = orderItems.value.filter(item => item.OrderId === order.PK)

      // Expand combo items
      const expandedItems: OrderItemWithDetails[] = []

      orderItemsForOrder.forEach(item => {
        const product = products.value.find(p => p.PK === item.ProductId)

        if (product) {
          // Check if it's a combo
          if (product.Category === 'combo' && product.ComboItems && product.ComboItems.length > 0) {
            // Add combo header
            expandedItems.push({
              ProductId: item.ProductId,
              Quantity: item.Quantity,
              Flavor: item.Flavor,
              productName: `${product.Name} ▼`,
              TotalPrice: item.TotalPrice
            })

            // Add each combo item as sub-item
            product.ComboItems.forEach((comboItem, idx) => {
              const comboProduct = products.value.find(p => p.PK === comboItem.ProductId)
              const comboFlavor = (item as any).ComboFlavors?.[idx] || ''

              if (comboProduct) {
                expandedItems.push({
                  ProductId: comboProduct.PK,
                  Quantity: comboItem.Quantity * item.Quantity, // Multiply by order quantity
                  Flavor: comboFlavor,
                  productName: `  └─ ${comboProduct.Name}`,
                  TotalPrice: 0 // Sub-items don't have individual prices
                })
              }
            })
          } else {
            // Regular product
            expandedItems.push({
              ProductId: item.ProductId,
              Quantity: item.Quantity,
              Flavor: item.Flavor,
              productName: product.Name,
              TotalPrice: item.TotalPrice
            })
          }
        }
      })

      return {
        ...order,
        pathfinderName: pathfinder?.Name || 'N/A',
        itemsWithDetails: expandedItems
      }
    })
  })

  const kitchenOrders = computed(() => {
    return ordersWithDetails.value
      .filter(order => ['pending', 'preparing', 'ready'].includes(order.Status))
      .sort((a, b) => new Date(a.CreatedAt).getTime() - new Date(b.CreatedAt).getTime())
  })

  // Financial tracking computed properties
  const pathfinderFinancialSummaries = computed((): PathfinderFinancialSummary[] => {
    return pathfinders.value.map(pathfinder => {
      const pathfinderFeesForMember = pathfinderFees.value.filter(
        pf => pf.PathfinderId === pathfinder.PK
      )

      const feesWithDetails: PathfinderFeeWithDetails[] = pathfinderFeesForMember.map(fee => ({
        ...fee,
        feeType: feeTypes.value.find(ft => ft.PK === fee.FeeTypeId),
        payments: payments.value.filter(p => p.PathfinderFeeId === fee.PK)
      }))

      const totalFeesAssigned = pathfinderFeesForMember.length
      const totalAmountOwed = pathfinderFeesForMember.reduce((sum, fee) => sum + fee.Amount, 0)
      const totalAmountPaid = pathfinderFeesForMember.reduce((sum, fee) => sum + fee.AmountPaid, 0)
      const totalAmountRemaining = pathfinderFeesForMember.reduce((sum, fee) => sum + fee.AmountRemaining, 0)
      const overdueFeesCount = pathfinderFeesForMember.filter(fee => fee.Status === 'overdue').length
      const paidFeesCount = pathfinderFeesForMember.filter(fee => fee.Status === 'paid').length
      const totalPaymentsMade = payments.value.filter(p => p.PathfinderId === pathfinder.PK).length

      return {
        pathfinder,
        totalFeesAssigned,
        totalAmountOwed,
        totalAmountPaid,
        totalAmountRemaining,
        overdueFeesCount,
        paidFeesCount,
        totalPaymentsMade,
        fees: feesWithDetails
      }
    })
  })

  const totalOutstandingBalance = computed(() => {
    return pathfinderFees.value.reduce((sum, fee) => sum + fee.AmountRemaining, 0)
  })

  const totalCollected = computed(() => {
    return pathfinderFees.value.reduce((sum, fee) => sum + fee.AmountPaid, 0)
  })

  const overdueFeesCount = computed(() => {
    return pathfinderFees.value.filter(fee => fee.Status === 'overdue').length
  })

  // Document tracking computed properties
  const documentCompletionStatuses = computed((): DocumentCompletionStatus[] => {
    return pathfinders.value.map(pathfinder => {
      const requiredDocs = getRequiredDocuments(pathfinder.Type)
      const totalRequired = requiredDocs.length

      const receivedDocs = requiredDocs.filter(docKey => {
        const docStatus = pathfinder.Documents[docKey as keyof DocumentStatusMap]
        return docStatus?.status === 'received'
      })
      const totalReceived = receivedDocs.length

      const missingDocuments = requiredDocs.filter(docKey => {
        const docStatus = pathfinder.Documents[docKey as keyof DocumentStatusMap]
        return !docStatus || docStatus.status === 'missing'
      })

      const completionPercentage = totalRequired > 0 ? Math.round((totalReceived / totalRequired) * 100) : 0

      return {
        pathfinder,
        totalRequired,
        totalReceived,
        completionPercentage,
        missingDocuments
      }
    })
  })

  const pathfindersWithIncompleteDocuments = computed(() => {
    return documentCompletionStatuses.value.filter(status => status.completionPercentage < 100)
  })

  // Helpers
  const activeCampaign = computed(() => campaigns.value.find(c => c.Status === 'active'))
  const selectedCampaign = computed(() => campaigns.value.find(c => c.PK === selectedCampaignId.value))

  // Export data for spreadsheet
  const exportToCSV = () => {
    const campaignName = selectedCampaign.value?.Name || 'Todas'
    const headers = ['Data', 'Pedido #', 'Desbravador', 'Cliente', 'Subtotal', 'Desconto', 'Total', 'Forma de Pagamento', 'Status']
    const rows = filteredOrders.value.map(order => {
      const pathfinder = pathfinders.value.find(p => p.PK === order.PathfinderId)

      const paymentMap: Record<string, string> = {
        'card': 'Cartão',
        'cash': 'Dinheiro',
        'pix-church': 'Pix Igreja',
        'pix-qr': 'Pix QR'
      }
      const paymentText = order.PaymentMethod ? (paymentMap[order.PaymentMethod] || order.PaymentMethod) : 'Pagar depois'

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
    link.download = `pedidos_${campaignName.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
  }

  const exportFinancialReport = () => {
    const headers = [
      'Nome',
      'Tipo',
      'Taxas Atribuídas',
      'Total Devido',
      'Total Pago',
      'Saldo Restante',
      'Taxas em Atraso',
      'Taxas Pagas',
      'Status'
    ]

    const rows = pathfinderFinancialSummaries.value.map(summary => {
      const typeText = {
        'desbravador': 'Desbravador',
        'staff': 'Staff',
        'directors': 'Diretoria'
      }[summary.pathfinder.Type] || summary.pathfinder.Type

      const status = summary.overdueFeesCount > 0
        ? 'Em Atraso'
        : summary.totalAmountRemaining > 0
        ? 'Pendente'
        : 'Em Dia'

      return [
        summary.pathfinder.Name,
        typeText,
        summary.totalFeesAssigned,
        `R$ ${summary.totalAmountOwed.toFixed(2).replace('.', ',')}`,
        `R$ ${summary.totalAmountPaid.toFixed(2).replace('.', ',')}`,
        `R$ ${summary.totalAmountRemaining.toFixed(2).replace('.', ',')}`,
        summary.overdueFeesCount,
        summary.paidFeesCount,
        status
      ]
    })

    const csvContent = [headers, ...rows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `relatorio_financeiro_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
  }

  const exportDocumentReport = () => {
    const headers = [
      'Nome',
      'Tipo',
      'Documentos Necessários',
      'Documentos Recebidos',
      'Conclusão (%)',
      'Documentos Faltando'
    ]

    const documentNames: Record<string, string> = {
      'id_cpf': 'RG + CPF',
      'sus_card': 'Cartão SUS',
      'proof_residence': 'Comprovante de Residência',
      'parent_id_cpf': 'RG + CPF dos Pais',
      'vaccination_card': 'Cartão de Vacinação',
      'criminal_background': 'Antecedentes Criminais',
      'health_insurance': 'Cartão de Plano de Saúde'
    }

    const rows = documentCompletionStatuses.value.map(status => {
      const typeText = {
        'desbravador': 'Desbravador',
        'staff': 'Staff',
        'directors': 'Diretoria'
      }[status.pathfinder.Type] || status.pathfinder.Type

      const missingDocsText = status.missingDocuments
        .map(doc => documentNames[doc] || doc)
        .join(', ') || 'Nenhum'

      return [
        status.pathfinder.Name,
        typeText,
        status.totalRequired,
        status.totalReceived,
        `${status.completionPercentage}%`,
        missingDocsText
      ]
    })

    const csvContent = [headers, ...rows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `relatorio_documentos_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
  }

  // Initialize store
  loadFromSupabase()

  return {
    // State
    pathfinders,
    orders,
    products,
    orderItems,
    campaigns,
    selectedCampaignId,
    feeTypes,
    pathfinderFees,
    payments,

    // Actions
    addPathfinder,
    updatePathfinder,
    deletePathfinder,
    addProduct,
    updateProduct,
    deleteProduct,
    getPriceHistory,
    addCampaign,
    updateCampaign,
    deleteCampaign,
    setSelectedCampaign,
    addOrder,
    updateOrder,
    updateOrderStatus,
    deleteOrder,
    loadFromSupabase,
    exportToCSV,

    // Fee Type Actions
    addFeeType,
    updateFeeType,
    deleteFeeType,

    // Pathfinder Fee Actions
    assignFeeToPathfinder,
    bulkAssignFee,
    updatePathfinderFee,
    waiveFee,
    deletePathfinderFee,

    // Payment Actions
    addPayment,
    deletePayment,

    // Document Actions
    getRequiredDocuments,
    updateDocumentStatus,
    bulkUpdateDocumentStatus,

    // Export Actions
    exportFinancialReport,
    exportDocumentReport,

    // Computed
    filteredOrders,
    totalSales,
    totalOrders,
    totalProductsSold,
    ordersByStatus,
    salesByPathfinder,
    salesByProduct,
    salesByPaymentMethod,
    topPathfinder,
    recentOrders,
    ordersWithDetails,
    kitchenOrders,
    activeCampaign,
    selectedCampaign,

    // Financial Computed
    pathfinderFinancialSummaries,
    totalOutstandingBalance,
    totalCollected,
    overdueFeesCount,

    // Document Computed
    documentCompletionStatuses,
    pathfindersWithIncompleteDocuments
  }
})