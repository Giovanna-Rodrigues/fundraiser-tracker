# 💾 Soluções de Backend Baratas para Sistema de Pedidos
 3. orders table

  id - uuid (primary key, default: gen_random_uuid())
  user_id - uuid (references auth.users(id))
  pathfinder_id - uuid (references pathfinders(id))
  customer_name - text
  subtotal - numeric(10,2)
  discount - numeric(10,2)
  total_amount - numeric(10,2)
  payment_method - text
  status - text (default: 'pending')
  date - date
  notes - text (nullable)
  created_at - timestamptz (default: now())

  4. order_items table

  id - uuid (primary key, default: gen_random_uuid())
  order_id - uuid (references orders(id) on delete cascade)
  product_id - uuid (references products(id))
  quantity - integer
  flavor - text (nullable)
  unit_price - numeric(10,2)
  total_price - numeric(10,2)
  created_at - timestamptz (default: now())

  RLS Policies for all tables:
  - Enable Row Level Security
  - SELECT: authenticated users can read their own data
  (user_id = auth.uid())
  - INSERT: authenticated users can create (user_id =
  auth.uid())
  - UPDATE: authenticated users can update their own data
  - DELETE: authenticated users can delete their own data

  Create these in order: pathfinders → products → orders →
  order_items
  
Para usar o sistema em múltiplos computadores (caixa e cozinha) simultaneamente, você precisará de um backend para sincronizar os dados. Aqui estão as opções mais baratas e práticas:

## 🔄 **Problema Atual: LocalStorage**
- ✅ **Vantagem**: Gratuito, funciona offline
- ❌ **Desvantagem**: Dados ficam isolados em cada computador
- ❌ **Limitação**: Não sincroniza entre dispositivos

---

## 🏆 **Opção 1: Supabase (RECOMENDADA)**
**💰 Custo: GRATUITO até 500MB**

### ✅ Vantagens:
- **Gratuito** para projetos pequenos (até 500MB)
- **PostgreSQL** completo na nuvem
- **APIs automáticas** para CRUD
- **Sincronização em tempo real**
- **Backup automático**
- Interface web para gerenciar dados

### 📋 Como Implementar:
1. Criar conta em [supabase.com](https://supabase.com)
2. Criar novo projeto (gratuito)
3. Configurar tabelas: `pathfinders`, `orders`, `order_items`
4. Substituir localStorage por chamadas à API do Supabase

### 📊 Capacidade:
- **45 pedidos**: ~5KB (muito abaixo do limite)
- **Bandwidth**: 2GB/mês (suficiente para centenas de pedidos/mês)

---

## 🔥 **Opção 2: Firebase Firestore**
**💰 Custo: GRATUITO até 1GB**

### ✅ Vantagens:
- **Gratuito** generoso (1GB armazenamento)
- **Sincronização em tempo real**
- **Offline-first** (funciona sem internet)
- **Google Cloud** (infraestrutura confiável)

### 📋 Como Implementar:
1. Criar projeto no [Firebase Console](https://console.firebase.google.com)
2. Habilitar Firestore Database
3. Configurar regras de segurança
4. Integrar com biblioteca Firebase no Vue

---

## 🌐 **Opção 3: Netlify + FaunaDB**
**💰 Custo: GRATUITO até 100MB**

### ✅ Vantagens:
- **Netlify**: Hospedagem gratuita para site
- **FaunaDB**: Banco serverless gratuito
- **Deploy automático** do GitHub
- **HTTPS** incluído

---

## 📱 **Opção 4: Google Sheets API**
**💰 Custo: GRATUITO**

### ✅ Vantagens:
- **Totalmente gratuito**
- **Familiar** (todos conhecem planilhas)
- **Backup automático** no Google Drive
- **Fácil visualização** dos dados

### ❌ Desvantagens:
- **Mais lento** que bancos dedicados
- **Limitações de sincronização** em tempo real

---

## 🖥️ **Opção 5: Servidor Local (Para quem tem conhecimento técnico)**
**💰 Custo: GRATUITO (usando computador próprio)**

### 📋 Configuração:
1. **Raspberry Pi** como servidor (~R$ 300 investimento único)
2. **Database**: SQLite ou PostgreSQL
3. **API**: Node.js + Express
4. **Rede local**: Acesso apenas na rede da igreja

### ✅ Vantagens:
- **Controle total** dos dados
- **Sem mensalidades**
- **Dados locais** (privacidade)

### ❌ Desvantagens:
- **Manutenção técnica** necessária
- **Backup manual**
- **Dependente da rede local**

---

## 🎯 **RECOMENDAÇÃO FINAL**

### Para sua campanha (45 pedidos):
**🏆 SUPABASE** é a melhor opção porque:

1. **Gratuito** para o seu volume
2. **Fácil implementação** (2-3 horas de desenvolvimento)
3. **Sincronização automática** entre caixa e cozinha
4. **Backup na nuvem**
5. **Escalável** se crescer no futuro

### 📝 **Implementação Supabase - Estimativa:**
- **Tempo**: 2-3 horas de desenvolvimento
- **Custo**: R$ 0,00
- **Resultado**: Sistema completo funcionando em tempo real

---

## 🔧 **Próximos Passos com Supabase:**

1. **Criar conta** em supabase.com
2. **Criar projeto** (escolher região Brazil - South America)
3. **Configurar tabelas**:
   ```sql
   -- Tabela de Desbravadores
   CREATE TABLE pathfinders (
     id SERIAL PRIMARY KEY,
     name TEXT NOT NULL,
     created_at TIMESTAMP DEFAULT NOW()
   );

   -- Tabela de Pedidos
   CREATE TABLE orders (
     id SERIAL PRIMARY KEY,
     pathfinder_id INTEGER REFERENCES pathfinders(id),
     customer_name TEXT NOT NULL,
     subtotal DECIMAL(10,2),
     discount DECIMAL(10,2),
     total_amount DECIMAL(10,2),
     payment_method TEXT,
     status TEXT DEFAULT 'pending',
     notes TEXT,
     order_date DATE,
     created_at TIMESTAMP DEFAULT NOW()
   );

   -- Tabela de Itens do Pedido
   CREATE TABLE order_items (
     id SERIAL PRIMARY KEY,
     order_id INTEGER REFERENCES orders(id),
     product_id INTEGER,
     quantity INTEGER,
     flavor TEXT,
     unit_price DECIMAL(10,2),
     total_price DECIMAL(10,2)
   );
   ```

4. **Obter credentials** da API
5. **Integrar no código Vue** (substituir localStorage)

### 📞 **Suporte:**
Se precisar de ajuda com a implementação, posso ajudar você a configurar o Supabase no sistema!

---

**Resultado**: Sistema profissional funcionando em tempo real entre caixa e cozinha, completamente gratuito para seu volume de vendas! 🚀