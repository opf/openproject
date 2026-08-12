---
name: api-documentation-generator
description: Generates OpenAPI/Swagger documentation from FastAPI endpoint code, type annotations, and docstrings. Creates interactive API documentation (Swagger UI, ReDoc) that stays in sync with code. Use when documenting endpoints, generating client SDKs, or validating API contracts.
---

# API Documentation Generator

This skill auto-generates API documentation that stays synchronized with endpoint code.

## When to use this skill

- Document endpoints: "Generate OpenAPI docs for API"
- Client SDK: "Create TypeScript client from API spec"
- API contract: "Validate endpoint definitions"
- Testing: "Use OpenAPI for integration tests"
- Sharing: "Export docs for external teams"

## How to use this skill

### Step 1: Run generator

```bash
python .agent/skills/api-documentation-generator/scripts/generate_docs.py
```

Options:
- **Generate OpenAPI** - Create OpenAPI spec from endpoints
- **Swagger UI** - Interactive API explorer
- **ReDoc** - Beautiful read-only documentation
- **Client SDK** - TypeScript/Python client generator
- **Export formats** - JSON, YAML, markdown

### Step 2: Review documentation

Generated files:
- `openapi.json` - Machine-readable spec
- `swagger-ui/` - Interactive explorer at `/docs`
- `redoc.html` - Rendered documentation
- `docs/` - Markdown documentation

### Step 3: Share with team

Documentation auto-updates when:
- Add new endpoints
- Change parameter types
- Update docstrings
- Modify response schemas

## OpenAPI Structure

### Automatic from FastAPI

FastAPI/Pydantic automatically generates:

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(
    title="ESG Sustainify API",
    version="1.0.0",
    description="Software solutions for ESG consulting"
)

class ClientCreate(BaseModel):
    """Request model for creating a client."""
    name: str
    industry: str = "Technology"

@app.post("/clients/", response_model=ClientCreate, tags=["clients"])
async def create_client(data: ClientCreate):
    """Create a new client company."""
    return data
```

Generates OpenAPI:

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "ESG Sustainify API",
    "version": "1.0.0"
  },
  "paths": {
    "/clients/": {
      "post": {
        "summary": "Create a new client company",
        "tags": ["clients"],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/ClientCreate"
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Successful response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/ClientCreate"
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

## Documentation Examples

### Endpoint with Full Details

```python
from typing import Optional

@router.post(
    "/clients/",
    response_model=ClientResponse,
    status_code=201,
    tags=["clients"],
    summary="Create a new client",
)
async def create_client(
    data: ClientCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Create a new client company.
    
    This endpoint creates a new ESG consulting client with:
    - Company name and industry
    - Initial configurations
    - Audit trail entry
    
    **Authentication**: Required (Bearer token)  
    **Permission**: clients.create
    
    **Request Body**:
    - name: Company name (required)
    - industry: Industry type (optional, defaults to "Technology")
    
    **Response**:
    - 201: Client created successfully
    - 400: Invalid input data
    - 401: Not authenticated
    - 403: Insufficient permissions
    
    **Example**:
    ```
    POST /api/v1/clients/
    Authorization: Bearer token_here
    Content-Type: application/json
    
    {
      "name": "Acme Corp",
      "industry": "Manufacturing"
    }
    ```
    
    Returns client object with id and timestamps.
    """
    return await client_service.create_client(db, data, current_user)
```

Generates Swagger:

```
POST /api/v1/clients/

Create a new client company

This endpoint creates a new ESG consulting client with:
- Company name and industry
- Initial configurations
- Audit trail entry

Authentication: Required (Bearer token)
Permission: clients.create

Request Body
  name* (string)
    Company name (required)
  
  industry (string)
    Industry type (optional, defaults to "Technology")

Responses
  201 Created
    Client created successfully
    Schema: ClientResponse
  
  400 Bad Request
    Invalid input data
  
  401 Unauthorized
    Not authenticated
  
  403 Forbidden
    Insufficient permissions

Example Request:
  curl -X POST "http://localhost:8000/api/v1/clients/" \
    -H "Authorization: Bearer token_here" \
    -H "Content-Type: application/json" \
    -d '{"name": "Acme Corp", "industry": "Manufacturing"}'

Example Response (201):
  {
    "id": 1,
    "name": "Acme Corp",
    "industry": "Manufacturing",
    "created_at": "2026-02-27T14:30:00",
    "updated_at": "2026-02-27T14:30:00"
  }
```

## Accessing Documentation

### Development

```bash
# Swagger UI (interactive)
http://localhost:8000/docs

# ReDoc (read-only)
http://localhost:8000/redoc

# OpenAPI JSON
http://localhost:8000/openapi.json
```

### Production Export

```bash
# Generate static files
python generate_docs.py --export-html

# Generated files:
# - html/swagger-ui/index.html   (interactive)
# - html/redoc.html              (read-only)
# - spec/openapi.json            (machine-readable)
# - docs/api.md                  (markdown)
```

## TypeScript Client Generation

From OpenAPI spec, generate type-safe client:

```bash
python generate_docs.py --generate-client typescript
```

Generates `frontend/lib/api-client-generated.ts`:

```typescript
export interface ClientCreate {
  name: string;
  industry?: string;
}

export interface ClientResponse extends ClientCreate {
  id: number;
  created_at: string;
  updated_at: string;
}

export namespace ClentsAPI {
  export async function create(data: ClientCreate): Promise<ClientResponse> {
    const response = await fetch("/api/v1/clients/", {
      method: "POST",
      body: JSON.stringify(data),
    });
    return response.json();
  }

  export async function list(): Promise<ClientResponse[]> {
    const response = await fetch("/api/v1/clients/");
    return response.json();
  }

  // ... other methods
}
```

## Export Formats

### OpenAPI JSON

```bash
python generate_docs.py --format json --output openapi.json
```

Standard format for:
- Client SDK generation
- API gateway configuration
- Contract testing
- Documentation generation

### OpenAPI YAML

```bash
python generate_docs.py --format yaml --output openapi.yaml
```

Human-readable version for git version control

### Markdown

```bash
python generate_docs.py --format markdown --output api.md
```

Readable documentation for READMEs, wikis

### AsyncAPI (for webhooks)

```bash
python generate_docs.py --format asyncapi --output asyncapi.json
```

For event-driven components

## Documentation Best Practices

✅ **Document purpose** - What does the endpoint do?  
✅ **Document parameters** - What inputs required?  
✅ **Document responses** - What are success/error cases?  
✅ **Add examples** - Show real request/response  
✅ **Note auth** - What permissions required?  
✅ **Update docstrings** - Keep synchronized with code  

❌ **Don't:**
- Leave TODOs in docstrings
- Document implementation details
- Forget status codes
- Make docs outdated
- Copy-paste without context

## Schema Documentation

### Request Schema

```python
class ClientCreate(BaseModel):
    """Request model for creating a client.
    
    Attributes:
        name: Company legal name (required, 1-255 chars)
        industry: Industry classification (optional)
        website: Company website URL (optional)
    
    Example:
        {
            "name": "Acme Corporation",
            "industry": "Manufacturing",
            "website": "https://acme.com"
        }
    """
    name: str = Field(..., min_length=1, max_length=255, description="Company name")
    industry: Optional[str] = Field(None, description="Industry type")
    website: Optional[str] = Field(None, description="Website URL")
```

### Response Schema

```python
class ClientResponse(ClientCreate):
    """Response model for client data.
    
    Extends request schema with:
    - id: Unique identifier
    - created_at: Creation timestamp
    - updated_at: Last modification timestamp
    - created_by: User who created
    """
    id: int
    created_at: datetime
    updated_at: datetime
    created_by: int
```

## Validation in Docs

Pydantic generates validation info:

```python
class ClientCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    # ↓ Documents in OpenAPI
    # name: required, string, minLength=1, maxLength=255
    
    age: int = Field(..., ge=0, le=150)
    # ↓ Documents in OpenAPI
    # age: required, integer, minimum=0, maximum=150
```

## See Also

- `vertical-slice-generator` - Generates endpoints with docs
- `code-quality-auditor` - Ensure docs are up-to-date
- `integration-test-generator` - Use OpenAPI for test generation
- `performance-profiler` - Document performance requirements
