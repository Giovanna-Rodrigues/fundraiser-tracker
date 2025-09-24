# 🏆 Sistema de Vendas - Campanha Desbravadores

Sistema web para controle e acompanhamento das vendas da campanha de arrecadação do Clube de Desbravadores, desenvolvido em Vue 3 com PrimeVue.

## 📋 Funcionalidades

### ✅ Dashboard Principal
- Visualização das métricas principais de vendas
- Gráficos de vendas por forma de pagamento
- Gráficos de produtos mais vendidos
- Top 5 desbravadores em vendas
- Vendas recentes
- Logo do clube em destaque

### ✅ Gestão de Desbravadores
- Cadastro de novos desbravadores
- Edição de informações dos desbravadores
- Exclusão de desbravadores (remove vendas associadas)
- Listagem com paginação

### ✅ Registro de Vendas
- Formulário para nova venda
- Seleção de desbravador, produto, quantidade
- Escolha da forma de pagamento (Cartão ou Pix)
- Cálculo automático do valor total
- Adição rápida de novos desbravadores

### ✅ Ranking de Vendas
- Pódio dos top 3 vendedores
- Ranking completo com estatísticas
- Detalhes individuais de cada desbravador
- Exportação do ranking para CSV

### 📦 Produtos Disponíveis
- **Mini Pizza** - R$ 5,00
- **Pastel de Pizza** - R$ 3,50
- **Pastel de Queijo** - R$ 3,50

### 💾 Armazenamento
- Dados salvos no localStorage do navegador
- Exportação para planilha CSV
- Persistência automática das informações

## 🚀 Como Executar

### Pré-requisitos
- Node.js (versão recomendada: 20.19+ ou 22.12+)
- npm

### Instalação
```bash
cd fundraiser-tracker
npm install
```

### Executar em Desenvolvimento
```bash
npm run dev
```

### Build para Produção
```bash
npm run build
npm run preview
```

## 🛠️ Tecnologias Utilizadas

- **Vue 3** - Framework JavaScript reativo
- **TypeScript** - Tipagem estática
- **PrimeVue** - Biblioteca de componentes UI
- **Chart.js** - Gráficos e visualizações
- **Pinia** - Gerenciamento de estado
- **Vue Router** - Roteamento
- **Vite** - Build tool

## 📱 Navegação

### Páginas Disponíveis:
- **Dashboard** (`/`) - Página principal com métricas
- **Nova Venda** (`/sales`) - Formulário de registro de vendas
- **Desbravadores** (`/pathfinders`) - Gestão de desbravadores
- **Ranking** (`/leaderboard`) - Classificação dos vendedores

## 💾 Estrutura de Dados

### Desbravador
```typescript
{
  id: number
  name: string
  email?: string
  phone?: string
  createdAt: string
}
```

### Venda
```typescript
{
  id: number
  pathfinderId: number
  productId: number
  quantity: number
  paymentMethod: 'card' | 'pix'
  totalAmount: number
  createdAt: string
  date: string
}
```

## 📊 Exportação de Dados

O sistema permite exportar:
- **Relatório completo de vendas** - Todas as vendas com detalhes
- **Ranking de desbravadores** - Classificação com estatísticas

Os arquivos são gerados em formato CSV, compatível com Excel e Google Sheets.

## 🎨 Interface

- Design responsivo para desktop e mobile
- Navegação intuitiva com menu superior
- Tema personalizado com cores do clube
- Logo do clube integrado à interface
- Feedback visual para todas as ações

## 🔧 Personalização

Para personalizar o sistema:

1. **Logo**: Substitua o arquivo `/public/logo.jpeg`
2. **Cores**: Edite as cores primárias em `src/main.ts`
3. **Produtos**: Modifique a lista em `src/stores/fundraiser.ts`

## 📝 Observações

- Os dados são armazenados localmente no navegador
- Recomenda-se fazer backup regular exportando os dados
- O sistema funciona offline após o primeiro carregamento
- Para uso em produção, considere implementar um backend

## 🆘 Suporte

Em caso de dúvidas ou problemas:
1. Verifique se todos os campos obrigatórios estão preenchidos
2. Confirme se o navegador suporta localStorage
3. Para problemas técnicos, consulte os logs do console

---

**Desenvolvido para o Clube de Desbravadores** 🏕️

*Sistema criado com Vue 3 + PrimeVue para facilitar o controle das vendas da campanha de arrecadação.*