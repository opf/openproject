# API Documentation Generator - Usage Examples

## Quick Start

### Generate All Documentation

```bash
cd .agent/skills/api-documentation-generator
python scripts/generate_docs.py

# Select: 1 (Generate all documentation)
```

**Output:**
```
╔════════════════════════════════════════════════════════════════╗
║    API Documentation Generator - ESG Sustainify               ║
║                                                                ║
║  Generate OpenAPI docs from FastAPI endpoint code             ║
╚════════════════════════════════════════════════════════════════╝

📋 Extracting OpenAPI specification...
✅ Generating OpenAPI JSON...
   Saved: backend/docs/api/openapi.json
✅ Generating Swagger UI...
   Saved: backend/docs/api/swagger-ui/index.html
✅ Generating TypeScript client...
   Saved: frontend/lib/api-client-generated.ts
✅ Generating Markdown docs...
   Saved: backend/docs/api/API.md

============================================================
✅ Documentation generated successfully!
============================================================

Accessible at:
  Swagger UI:  backend/docs/api/swagger-ui/index.html
  OpenAPI:     backend/docs/api/openapi.json
  Markdown:    backend/docs/api/API.md
  TS Client:   frontend/lib/api-client-generated.ts
```

## OpenAPI Specification

### Generated File: `openapi.json`

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "ESG Sustainify API",
    "version": "1.0.0",
    "description": "RESTful API for ESG sustainability consulting"
  },
  "servers": [
    {
      "url": "http://localhost:8000",
      "description": "Development"
    },
    {
      "url": "https://api.esg.com",
      "description": "Production"
    }
  ],
  "paths": {
    "/api/v1/clients/": {
      "get": {
        "summary": "List all clients",
        "tags": ["clients"],
        "responses": {
          "200": {
            "description": "List of clients",
            "content": {
              "application/json": {
                "schema": {
                  "type": "array",
                  "items": {
                    "$ref": "#/components/schemas/ClientResponse"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

## Interactive Swagger UI

View live at: `backend/docs/api/swagger-ui/index.html`

**Features:**
- 🔍 Try API calls directly from browser
- 📖 View request/response schemas
- 🔐 Test authentication
- 📋 See all endpoints in one place

### Using Swagger to Test Endpoints

1. Open `swagger-ui/index.html` in browser
2. Click "Authorize" button
3. Enter your JWT token: `Bearer <your_token>`
4. Find endpoint (e.g., GET /api/v1/clients/)
5. Click "Try it out"
6. Enter parameters
7. Click "Execute"
8. View response

**Example Request:**
```
GET /api/v1/clients/

Response:
[
  {
    "id": 1,
    "name": "Acme Corp",
    "industry": "Manufacturing",
    "created_at": "2024-01-15T10:30:00Z"
  }
]
```

## TypeScript Client SDK

### Generated File: `api-client-generated.ts`

```typescript
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Client types
export interface ClientCreate {
  name: string;
  industry?: string;
}

export interface ClientResponse extends ClientCreate {
  id: number;
  created_at: string;
  updated_at: string;
  created_by: number;
}

// Client API
export const clientsAPI = {
  list: () => apiClient.get<ClientResponse[]>('/api/v1/clients/'),
  
  create: (data: ClientCreate) => 
    apiClient.post<ClientResponse>('/api/v1/clients/', data),
  
  get: (id: number) => 
    apiClient.get<ClientResponse>(`/api/v1/clients/${id}/`),
  
  update: (id: number, data: Partial<ClientCreate>) => 
    apiClient.put<ClientResponse>(`/api/v1/clients/${id}/`, data),
  
  delete: (id: number) => 
    apiClient.delete(`/api/v1/clients/${id}/`),
};

export default apiClient;
```

### Using Generated Client in React

```typescript
'use client';

import { useQuery, useMutation } from '@tanstack/react-query';
import { clientsAPI } from '@/lib/api-client-generated';

export function ClientList() {
  const { data: clients, isLoading } = useQuery({
    queryKey: ['clients'],
    queryFn: () => clientsAPI.list(),
  });

  const createMutation = useMutation({
    mutationFn: (name: string) => 
      clientsAPI.create({ name, industry: 'Tech' }),
  });

  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      {clients?.map(client => (
        <div key={client.id}>{client.name}</div>
      ))}
      
      <button 
        onClick={() => createMutation.mutate('New Client')}
        disabled={createMutation.isPending}
      >
        Create Client
      </button>
    </div>
  );
}
```

## Markdown Documentation

### Generated File: `API.md`

```markdown
# ESG Sustainify API Documentation

RESTful API for ESG sustainability consulting

## Base URL

- Development: `http://localhost:8000`
- Production: `https://api.esg.com`

## Authentication

All endpoints (except public ones) require Bearer token:

```
Authorization: Bearer <your_access_token>
```

## Endpoints

### /api/v1/clients/

#### GET /api/v1/clients/
**Summary**: List all clients
**Tags**: clients

#### POST /api/v1/clients/
**Summary**: Create a new client
**Tags**: clients
**Security**: Requires authentication

### /api/v1/clients/{id}

#### GET /api/v1/clients/{id}
**Summary**: Get client details
**Tags**: clients

#### PUT /api/v1/clients/{id}
**Summary**: Update client
**Tags**: clients

#### DELETE /api/v1/clients/{id}
**Summary**: Delete client
**Tags**: clients
```

## Export Formats

### Generate Only OpenAPI JSON

```bash
python scripts/generate_docs.py
# Select: 2 (OpenAPI spec only)
```

### Share Documentation

**For API consumers:**
1. Send Swagger UI link
2. Or include markdown docs in README
3. Or provide TypeScript client package

## Integration Patterns

### Frontend - Use Generated Client

```typescript
// lib/services/client.ts
import { clientsAPI } from '@/lib/api-client-generated';
import { useQuery } from '@tanstack/react-query';

export function useClients() {
  return useQuery({
    queryKey: ['clients'],
    queryFn: async () => {
      const response = await clientsAPI.list();
      return response.data;
    },
  });
}
```

### Backend - Auto-Generate Docs

In FastAPI endpoint:

```python
from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/clients", tags=["clients"])

@router.get("/", response_model=List[ClientResponse])
async def list_clients(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all clients accessible to the user."""
    return await client_service.get_all_clients(db, current_user)
```

FastAPI auto-generates documentation from:
- Function signature
- Type hints (response_model)
- Docstring
- Parameter annotations

## Troubleshooting

### Issue: "No endpoints found"

Solution: Ensure FastAPI app is running and all routers are included

```python
# app/main.py
from app.api.v1 import endpoints

app = FastAPI()
app.include_router(endpoints.clients.router)  # Must include router!
```

### Issue: "Swagger UI shows 'Failed to fetch spec'"

Solution: Check FastAPI is running and /openapi.json is accessible

```bash
curl http://localhost:8000/openapi.json
```

### Issue: "Generated TS client has wrong types"

Solution: Add type hints to FastAPI responses

```python
# BEFORE (no types shown in API doc)
@router.post("/clients/")
async def create_client(data):
    return result

# AFTER (types auto-generated)
@router.post("/clients/", response_model=ClientResponse)
async def create_client(data: ClientCreate):
    return result
```

## CI/CD Integration

Generate docs on every commit:

```yaml
# .github/workflows/docs.yml
name: Generate API Docs

on: [push]

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Generate Docs
        run: |
          pip install fastapi
          python .agent/skills/api-documentation-generator/scripts/generate_docs.py
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: backend/docs/api/swagger-ui
```

## Best Practices

✅ **DO**:
- Keep docstrings updated with endpoint descriptions
- Use type hints for all request/response bodies
- Tag related endpoints (users, clients, tools)
- Include examples in docstrings

❌ **DON'T**:
- Hardcode URLs in client SDK
- Skip type hints
- Use generic response_model=List
- Mix multiple resources in one endpoint

## Success Criteria

✅ Swagger UI loads without errors
✅ Generated client has proper TypeScript types
✅ All endpoints documented with examples
✅ Client SDK exports all API operations
