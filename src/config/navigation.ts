export interface MenuItem {
  path: string
  label: string
  icon: string
}

export interface MenuSection {
  title: string
  icon: string
  items: MenuItem[]
}

export const menuSections: MenuSection[] = [
  {
    title: 'Operações',
    icon: 'pi pi-briefcase',
    items: [
      { path: '/', label: 'Dashboard', icon: 'pi pi-home' },
      { path: '/orders', label: 'Novo Pedido', icon: 'pi pi-plus' },
      { path: '/kitchen', label: 'Cozinha', icon: 'pi pi-stopwatch' }
    ]
  },
  {
    title: 'Gestão',
    icon: 'pi pi-cog',
    items: [
      { path: '/pathfinders', label: 'Desbravadores', icon: 'pi pi-users' },
      { path: '/products', label: 'Produtos', icon: 'pi pi-box' },
      { path: '/campaigns', label: 'Campanhas', icon: 'pi pi-flag' }
    ]
  },
  {
    title: 'Relatórios',
    icon: 'pi pi-chart-bar',
    items: [
      { path: '/leaderboard', label: 'Ranking', icon: 'pi pi-trophy' },
      { path: '/cost-calculation', label: 'Custos', icon: 'pi pi-calculator' }
    ]
  }
]