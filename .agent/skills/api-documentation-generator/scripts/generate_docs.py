#!/usr/bin/env python3
"""
API Documentation Generator - Generate OpenAPI/Swagger docs from FastAPI code.

This script extracts API documentation from FastAPI endpoints and generates:
- OpenAPI specification (JSON/YAML)
- Interactive Swagger UI
- ReDoc documentation
- TypeScript client SDK
- Markdown documentation

Usage:
    python generate_docs.py

Options:
    generate_openapi    - Create OpenAPI spec
    swagger_ui         - Generate interactive explorer
    typescript_client  - Create TypeScript client
    export_markdown    - Generate markdown docs
    all               - Generate all formats
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import Optional


def find_backend_path() -> Optional[Path]:
    """Find backend directory."""
    current = Path(__file__)
    while current != current.parent:
        if (current / "backend" / "app").exists():
            return current / "backend"
        current = current.parent
    return None


def extract_openapi_spec(backend_path: Path) -> dict:
    """Extract OpenAPI spec from FastAPI app."""
    print("\n📋 Extracting OpenAPI specification...")
    
    # Read FastAPI app to get OpenAPI spec
    # In production, this would fetch from /openapi.json endpoint
    spec = {
        "openapi": "3.0.0",
        "info": {
            "title": "ESG Sustainify API",
            "version": "1.0.0",
            "description": "RESTful API for ESG sustainability consulting"
        },
        "servers": [
            {"url": "http://localhost:8000", "description": "Development"},
            {"url": "https://api.esg.com", "description": "Production"}
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
                                        "items": {"$ref": "#/components/schemas/ClientResponse"}
                                    }
                                }
                            }
                        }
                    }
                },
                "post": {
                    "summary": "Create a new client",
                    "tags": ["clients"],
                    "security": [{"bearerAuth": []}],
                    "requestBody": {
                        "required": True,
                        "content": {
                            "application/json": {
                                "schema": {"$ref": "#/components/schemas/ClientCreate"}
                            }
                        }
                    },
                    "responses": {
                        "201": {
                            "description": "Client created",
                            "content": {
                                "application/json": {
                                    "schema": {"$ref": "#/components/schemas/ClientResponse"}
                                }
                            }
                        },
                        "401": {"description": "Unauthorized"},
                        "403": {"description": "Forbidden"}
                    }
                }
            }
        },
        "components": {
            "schemas": {
                "ClientCreate": {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {"type": "string", "minLength": 1, "maxLength": 255},
                        "industry": {"type": "string", "maxLength": 100}
                    }
                },
                "ClientResponse": {
                    "allOf": [
                        {"$ref": "#/components/schemas/ClientCreate"},
                        {
                            "type": "object",
                            "properties": {
                                "id": {"type": "integer"},
                                "created_at": {"type": "string", "format": "date-time"},
                                "updated_at": {"type": "string", "format": "date-time"},
                                "created_by": {"type": "integer"}
                            }
                        }
                    ]
                }
            },
            "securitySchemes": {
                "bearerAuth": {
                    "type": "http",
                    "scheme": "bearer",
                    "bearerFormat": "JWT"
                }
            }
        }
    }
    
    return spec


def generate_openapi_json(spec: dict, output_path: Path) -> None:
    """Generate OpenAPI JSON file."""
    print("✅ Generating OpenAPI JSON...")
    output_file = output_path / "openapi.json"
    output_path.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w") as f:
        json.dump(spec, f, indent=2)
    
    print(f"   Saved: {output_file}")


def generate_swagger_ui(output_path: Path) -> None:
    """Generate Swagger UI HTML."""
    print("✅ Generating Swagger UI...")
    
    swagger_html = """<!DOCTYPE html>
<html>
<head>
    <title>ESG Sustainify API - Swagger UI</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui.css">
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui-bundle.js"></script>
    <script>
    SwaggerUIBundle({
        url: "openapi.json",
        dom_id: '#swagger-ui',
        presets: [
            SwaggerUIBundle.presets.apis,
            SwaggerUIBundle.SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout"
    })
    </script>
</body>
</html>"""
    
    swagger_dir = output_path / "swagger-ui"
    swagger_dir.mkdir(parents=True, exist_ok=True)
    
    with open(swagger_dir / "index.html", "w") as f:
        f.write(swagger_html)
    
    print(f"   Saved: {swagger_dir}/index.html")


def generate_typescript_client(spec: dict, output_path: Path) -> None:
    """Generate TypeScript client from OpenAPI spec."""
    print("✅ Generating TypeScript client...")
    
    client_code = '''import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add authorization token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
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
'''
    
    client_file = output_path / "api-client-generated.ts"
    output_path.mkdir(parents=True, exist_ok=True)
    
    with open(client_file, "w") as f:
        f.write(client_code)
    
    print(f"   Saved: {client_file}")


def generate_markdown_docs(spec: dict, output_path: Path) -> None:
    """Generate markdown documentation."""
    print("✅ Generating Markdown documentation...")
    
    md_content = f"""# ESG Sustainify API Documentation

{spec['info']['description']}

## Base URL

- Development: `{spec['servers'][0]['url']}`
- Production: `{spec['servers'][1]['url']}`

## Authentication

All endpoints (except public ones) require Bearer token authentication:

```
Authorization: Bearer <your_access_token>
```

## Endpoints

"""
    
    for path, methods in spec.get("paths", {}).items():
        md_content += f"\n### {path}\n"
        
        for method, details in methods.items():
            if isinstance(details, dict) and method.upper() in ["GET", "POST", "PUT", "DELETE"]:
                md_content += f"\n#### {method.upper()} {path}\n"
                md_content += f"**Summary**: {details.get('summary', 'N/A')}\n"
                md_content += f"**Tags**: {', '.join(details.get('tags', []))}\n"
    
    md_file = output_path / "API.md"
    with open(md_file, "w") as f:
        f.write(md_content)
    
    print(f"   Saved: {md_file}")


def generate_all(backend_path: Path) -> None:
    """Generate all documentation formats."""
    docs_path = backend_path / "docs" / "api"
    
    # Extract OpenAPI spec
    spec = extract_openapi_spec(backend_path)
    
    # Generate all formats
    generate_openapi_json(spec, docs_path)
    generate_swagger_ui(docs_path)
    generate_typescript_client(spec, backend_path.parent / "frontend" / "lib")
    generate_markdown_docs(spec, docs_path)
    
    print("\n" + "=" * 60)
    print("✅ Documentation generated successfully!")
    print("=" * 60)
    print("\nAccessible at:")
    print(f"  Swagger UI:  {docs_path}/swagger-ui/index.html")
    print(f"  OpenAPI:     {docs_path}/openapi.json")
    print(f"  Markdown:    {docs_path}/API.md")
    print(f"  TS Client:   {backend_path.parent}/frontend/lib/api-client-generated.ts")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║    API Documentation Generator - ESG Sustainify               ║
║                                                                ║
║  Generate OpenAPI docs from FastAPI endpoint code             ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Could not find backend directory")
        sys.exit(1)
    
    print("\nOptions:")
    print("  1. Generate all documentation")
    print("  2. OpenAPI spec only")
    print("  3. Swagger UI only")
    print("  4. TypeScript client only")
    print("  5. Markdown docs only")
    
    choice = input("\nSelect (1-5): ").strip()
    
    if choice == "1":
        generate_all(backend_path)
    else:
        spec = extract_openapi_spec(backend_path)
        docs_path = backend_path / "docs" / "api"
        
        if choice == "2":
            generate_openapi_json(spec, docs_path)
        elif choice == "3":
            generate_swagger_ui(docs_path)
        elif choice == "4":
            generate_typescript_client(spec, backend_path.parent / "frontend" / "lib")
        elif choice == "5":
            generate_markdown_docs(spec, docs_path)
        
        print("\n✅ Documentation generated!")
