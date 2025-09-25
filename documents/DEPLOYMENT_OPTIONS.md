# Deployment & Hosting Options for Fundraiser Tracker

## Current Application Overview
- **Tech Stack**: Vue 3 + TypeScript + PrimeVue + Pinia
- **Current Storage**: localStorage (client-side only)
- **Users**: 3-5 concurrent users (cashier + kitchen stations)
- **Use Case**: Pathfinder club fundraiser campaign management

## Option 1: Vercel + Supabase (Recommended for Simplicity)

### Vercel Frontend Hosting
- **Free Tier**:
  - 100GB bandwidth/month
  - 100 serverless function executions/day
  - Unlimited static deployments
- **Cost**: **$0/month** (very likely to stay in free tier)
- **Pro Tier**: $20/month (only if exceeding free limits)

### Supabase Backend Database
- **Free Tier**:
  - 500MB database storage
  - 2 projects
  - 50,000 monthly active users
  - Real-time subscriptions
- **Cost**: **$0/month** for your use case
- **Pro Tier**: $25/month (only if exceeding limits)

### **Total Estimated Cost: $0-5/month**

### Implementation Steps:
1. **Deploy to Vercel**:
   ```bash
   npm run build
   vercel --prod
   ```

2. **Setup Supabase**:
   - Create tables: pathfinders, products, orders, order_items
   - Replace localStorage with Supabase client
   - Add real-time updates for kitchen orders

3. **Migration Effort**: ~4-8 hours
   - Replace Pinia store with Supabase queries
   - Add real-time subscriptions
   - Update authentication to use Supabase Auth

---

## Option 2: AWS Microservices (Full Cloud Architecture)

### Architecture Components

#### DynamoDB (Database)
- **Tables Needed**: 5 tables
  - `Users` (pathfinders + auth users)
  - `Products`
  - `Orders`
  - `OrderItems`
  - `Sessions` (for auth)
- **Free Tier**: 25GB storage, 25 RCU/WCU per table
- **Cost**: **$0/month** (your data would be <1GB total)

#### Cognito (Authentication)
- **Free Tier**: 50,000 Monthly Active Users
- **Cost**: **$0/month** (you have max 5 users)

#### AppSync (GraphQL API)
- **Free Tier**: 250,000 requests/month
- **Real-time subscriptions**: 250,000 connection minutes
- **Cost**: **$0/month** (estimated 1,000-5,000 requests/month)

#### Lambda (Python Resolvers)
- **Free Tier**: 1M requests + 400,000 GB-seconds
- **Estimated usage**: 2,000-10,000 invocations/month
- **Cost**: **$0-2/month**

#### Amplify (Frontend Hosting)
- **Free Tier**: 1,000 build minutes, 15GB bandwidth/month
- **Cost**: **$0/month**

### **Total Estimated Cost: $0-5/month**

### Sample Architecture:
```
Frontend (Vue + Amplify)
    ↓
AppSync GraphQL API
    ↓
Lambda Resolvers (Python)
    ↓
DynamoDB Tables
    ↓
Cognito (Auth)
```

### Implementation Steps:
1. **Setup Amplify Project**:
   ```bash
   npm install -g @aws-amplify/cli
   amplify init
   amplify add auth
   amplify add api
   amplify add hosting
   ```

2. **Create GraphQL Schema**:
   ```graphql
   type Order @model @auth(rules: [{allow: private}]) {
     id: ID!
     pathfinderId: ID!
     customerName: String!
     items: [OrderItem] @connection(keyName: "byOrder", fields: ["id"])
     status: OrderStatus!
     totalAmount: Float!
     createdAt: AWSDateTime
   }

   type OrderItem @model @key(name: "byOrder", fields: ["orderId"]) {
     id: ID!
     orderId: ID!
     productId: ID!
     quantity: Int!
     unitPrice: Float!
   }
   ```

3. **Migration Effort**: ~2-3 weeks
   - Complete backend setup
   - GraphQL integration
   - Authentication migration
   - Real-time subscriptions
   - Testing and deployment

---

## Comparison Summary

| Feature | Vercel + Supabase | AWS Microservices |
|---------|------------------|-------------------|
| **Setup Time** | 4-8 hours | 2-3 weeks |
| **Complexity** | Low | High |
| **Cost** | $0-5/month | $0-5/month |
| **Scalability** | Good (handles 100s of users) | Excellent (enterprise scale) |
| **Learning Curve** | Minimal | Steep |
| **Real-time Updates** | ✅ Built-in | ✅ Via subscriptions |
| **Authentication** | ✅ Simple | ✅ Enterprise-grade |
| **Maintenance** | Low | Medium-High |

---

## Recommendation

**For your Pathfinder fundraiser campaign: Go with Vercel + Supabase**

### Reasons:
1. **Time to Market**: Deploy in hours, not weeks
2. **Simplicity**: Minimal learning curve
3. **Cost**: Effectively free for your use case
4. **Sufficient Features**: Real-time updates, auth, database
5. **Future-Proof**: Easy to migrate later if needed

### When to Choose AWS:
- You want to learn AWS ecosystem
- You plan to scale to 100+ concurrent users
- You need enterprise-grade compliance
- You have time for complex setup

---

## Current Application Status

### Implemented Features:
- ✅ Order entry with multi-item support
- ✅ Kitchen workflow management
- ✅ Pathfinder performance tracking
- ✅ Sales reporting and export
- ✅ Responsive design
- ✅ Authentication system
- ✅ Role-based access (admin, cashier, kitchen)

### Migration Requirements:
- Replace localStorage with database
- Add real-time order updates
- Implement proper user authentication
- Add data synchronization between stations

### Mock Users (Current):
- `admin` / `admin123` (admin role)
- `caixa` / `caixa123` (cashier role)
- `cozinha` / `cozinha123` (kitchen role)

---

## Next Steps

1. **Choose deployment option** based on your priorities
2. **Backup current localStorage data** before migration
3. **Set up development/staging environment** first
4. **Test thoroughly** with multiple users
5. **Plan cutover strategy** for live fundraiser events

## Resources

### Vercel + Supabase:
- [Vercel Documentation](https://vercel.com/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Vue + Supabase Tutorial](https://supabase.com/docs/guides/getting-started/tutorials/with-vue-3)

### AWS Amplify:
- [AWS Amplify Documentation](https://docs.amplify.aws/)
- [Vue + Amplify Tutorial](https://docs.amplify.aws/start/getting-started/installation/q/integration/vue/)
- [AppSync GraphQL Guide](https://docs.aws.amazon.com/appsync/)