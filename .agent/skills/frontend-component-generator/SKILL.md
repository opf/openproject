---
name: frontend-component-generator
description: Generates React components with TypeScript types, hooks, and styling using shadcn/ui and Tailwind CSS. Creates functional components following ESG patterns (THEME system, api-client, form handling). Use when building new UI components, pages, or forms for the frontend.
---

# Frontend Component Generator

This skill generates React components with proper TypeScript typing, state management, and styling.

## When to use this skill

- New page: "Create a new clients list page"
- Form component: "Generate a client edit form"
- Reusable component: "Create a client card component"
- Dialog/modal: "Create select company dialog"
- Table: "Generate sortable table for contacts"

## How to use this skill

### Step 1: Run generator

```bash
python .agent/skills/frontend-component-generator/scripts/generate_component.py
```

Prompts:
- **Component name** (PascalCase): ClientList, EditClientForm
- **Component type**: Page, Card, Form, Table, Dialog
- **Features**: Sorting, filtering, pagination, forms
- **Location**: Where to create file

### Step 2: Review generated component

Created in:
```
frontend/components/{component_name}/{component_name}.tsx
```

Or pages:
```
frontend/app/(staff)/clients/page.tsx
```

### Step 3: Customize

Generated files have TODO comments for:
- API integration
- Form logic
- Styling tweaks
- Business logic

### Step 4: Add to page

Import and use in parent component:

```tsx
import { ClientList } from "@/components/clients/ClientList";

export default function ClientsPage() {
  return <ClientList />;
}
```

## Component Types

### List Component

Display items in table/cards:

```tsx
interface Client {
  id: number;
  name: string;
  industry: string;
  created_at: string;
}

export const ClientList: React.FC = () => {
  const { data: clients } = useQuery({
    queryKey: ["clients"],
    queryFn: () => clientService.list(),
  });

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Name</TableHead>
          <TableHead>Industry</TableHead>
          <TableHead>Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {clients?.map(client => (
          <TableRow key={client.id}>
            <TableCell>{client.name}</TableCell>
            <TableCell>{client.industry}</TableCell>
            <TableCell>
              <Button variant="ghost">Edit</Button>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
};
```

### Form Component

Handle user input:

```tsx
export const ClientForm: React.FC<{ clientId?: number }> = ({ clientId }) => {
  const form = useForm<ClientFormData>({
    resolver: zodResolver(clientSchema),
  });

  const onSubmit = async (data: ClientFormData) => {
    if (clientId) {
      await clientService.update(clientId, data);
    } else {
      await clientService.create(data);
    }
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <FormField control={form.control} name="name" render={({ field }) => (
        <FormItem>
          <FormLabel>Company Name</FormLabel>
          <FormControl>
            <Input placeholder="Acme Corp" {...field} />
          </FormControl>
        </FormItem>
      )} />
      <Button type="submit">Save</Button>
    </form>
  );
};
```

### Card Component

Self-contained display unit:

```tsx
interface ClientCardProps {
  client: Client;
  onEdit?: (id: number) => void;
  onDelete?: (id: number) => void;
}

export const ClientCard: React.FC<ClientCardProps> = ({ 
  client, 
  onEdit, 
  onDelete 
}) => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{client.name}</CardTitle>
        <CardDescription>{client.industry}</CardDescription>
      </CardHeader>
      <CardContent>
        {/* Client details */}
      </CardContent>
      <CardFooter className="gap-2">
        <Button onClick={() => onEdit?.(client.id)}>Edit</Button>
        <Button variant="destructive" onClick={() => onDelete?.(client.id)}>
          Delete
        </Button>
      </CardFooter>
    </Card>
  );
};
```

### Dialog Component

Modal/popup interface:

```tsx
export const SelectClientDialog: React.FC<{
  open: boolean;
  onSelect: (client: Client) => void;
  onOpenChange: (open: boolean) => void;
}> = ({ open, onSelect, onOpenChange }) => {
  const { data: clients } = useQuery({
    queryKey: ["clients"],
    queryFn: () => clientService.list(),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Select Client</DialogTitle>
        </DialogHeader>
        <div className="grid gap-2">
          {clients?.map(client => (
            <button
              key={client.id}
              onClick={() => {
                onSelect(client);
                onOpenChange(false);
              }}
              className="text-left p-2 hover:bg-accent"
            >
              {client.name}
            </button>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
};
```

## Hooks & Patterns

### Data Fetching

```tsx
const { data, isLoading, error } = useQuery({
  queryKey: ["clients"],
  queryFn: () => clientService.list(),
});

if (isLoading) return <div>Loading...</div>;
if (error) return <div>Error loading clients</div>;
```

### State Management

```tsx
const [selectedId, setSelectedId] = useState<number | null>(null);
const [filters, setFilters] = useState({ industry: "" });
```

### Mutations

```tsx
const mutation = useMutation({
  mutationFn: (data: ClientCreate) => clientService.create(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ["clients"] });
  },
});

const handleCreate = (data: ClientCreate) => {
  mutation.mutate(data);
};
```

### Forms

```tsx
const form = useForm<FormData>({
  resolver: zodResolver(schema),
  defaultValues: client,
});

const onSubmit = async (data: FormData) => {
  try {
    await clientService.update(client.id, data);
  } catch (error) {
    form.setError("root", { message: getErrorMessage(error) });
  }
};
```

## Styling Patterns

### Using THEME

```tsx
import { THEME } from "@/styles/theme";

<div style={{ 
  backgroundColor: THEME.colors.primary,
  padding: THEME.spacing.md,
}}>
  Content
</div>
```

### Using Tailwind

```tsx
<div className="bg-primary text-white p-4 rounded-lg">
  Content with THEME-based Tailwind
</div>
```

### shadcn/ui Components

Available components:

```tsx
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell } from "@/components/ui/table";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { 
  Form, 
  FormField, 
  FormItem, 
  FormLabel 
} from "@/components/ui/form";
```

## Component Structure

### Single File

For simple components:

```
frontend/components/clients/ClientCard.tsx
```

### Directory Structure

For complex components:

```
frontend/components/clients/
├── ClientList.tsx          (List view)
├── ClientForm.tsx          (Edit/create form)
├── ClientCard.tsx          (Individual card)
└── ClientFilters.tsx       (Filter bar)
```

### Page Structure

```
frontend/app/(staff)/clients/
├── page.tsx                (List page)
├── [id]/
│   └── page.tsx            (Detail page)
└── new/
    └── page.tsx            (Create page)
```

## Generated Component Example

```tsx
"use client";

import React, { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { THEME } from "@/styles/theme";
import { clientService } from "@/lib/services/client-service";
import type { Client } from "@/lib/types/client";

/**
 * ClientList Component
 * 
 * Displays a list of clients in a table with actions (edit, delete).
 * Uses TanStack Query for data fetching and invalidation.
 */
export const ClientList: React.FC = () => {
  const { data: clients, isLoading, error } = useQuery({
    queryKey: ["clients"],
    queryFn: () => clientService.list(),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => clientService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["clients"] });
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading clients</div>;

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">Clients</h1>
        <Button>Create Client</Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Industry</TableHead>
            <TableHead>Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {clients?.map(client => (
            <TableRow key={client.id}>
              <TableCell>{client.name}</TableCell>
              <TableCell>{client.industry}</TableCell>
              <TableCell className="gap-2">
                <Button variant="ghost" size="sm">Edit</Button>
                <Button 
                  variant="destructive" 
                  size="sm"
                  onClick={() => deleteMutation.mutate(client.id)}
                >
                  Delete
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
};
```

## Best Practices

✅ **Use hooks** - React 18+ functional components  
✅ **Type everything** - Full TypeScript coverage  
✅ **Use THEME** - No hardcoded colors  
✅ **Use shadcn/ui** - Consistent components  
✅ **Use TanStack Query** - Data fetching  
✅ **Use React Hook Form** - Form handling  
✅ **Keep components small** - < 150 LOC  
✅ **Separate concerns** - Data fetching, UI, logic  

❌ **Don't:**
- Use class components
- Use `any` type
- Hardcode API URLs
- Hardcode colors
- Put business logic in components
- Make components too large

## Testing Components

Example test:

```tsx
import { render, screen } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ClientList } from "./ClientList";

describe("ClientList", () => {
  it("renders loading state", () => {
    render(
      <QueryClientProvider client={new QueryClient()}>
        <ClientList />
      </QueryClientProvider>
    );
    expect(screen.getByText("Loading...")).toBeInTheDocument();
  });
});
```

## See Also

- `vertical-slice-generator` - Generates components automatically
- `test-runner` - Test frontend components
- `progress-tracker` - Track UI completion
