# Frontend Component Generator - Usage Examples

This guide shows how to use the frontend-component-generator skill.

## Example 1: Generate List Component

```bash
python .agent/skills/frontend-component-generator/scripts/generate_component.py
```

**Prompts:**

```
Component Type:
  1. List component
  2. Form component
  3. Dialog component
  4. Custom hook

Select (1-4): 1

Component name (PascalCase): ClientList

Entity name (e.g., Client): Client
```

**Generated file:**

`frontend/components/client/ClientList.tsx`

```tsx
"use client";

import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
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

/**
 * ClientList Component
 * 
 * Displays a list of Client items in a table format.
 * Features:
 * - Sorting
 * - Filtering
 * - Pagination
 * - Actions (edit, delete)
 */

interface Client {
  id: number;
  name: string;
  created_at: string;
  // TODO: Add other fields
}

export const ClientList: React.FC = () => {
  const [page, setPage] = useState(1);
  
  // TODO: Import service
  // const { data, isLoading, error } = useQuery({
  //   queryKey: ["clients", page],
  //   queryFn: () => clientService.list({ page }),
  // });

  // if (isLoading) return <div>Loading...</div>;
  // if (error) return <div>Error loading clients</div>;

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
            <TableHead>Created</TableHead>
            <TableHead>Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {/* TODO: Map over clients */}
        </TableBody>
      </Table>
    </div>
  );
};
```

## Next Steps for List Component

1. **Replace TODO comments:**

```tsx
// Add import at top
import { clientService } from "@/lib/services/client-service";

// Replace TODO in component
const { data: clients, isLoading, error } = useQuery({
  queryKey: ["clients"],
  queryFn: () => clientService.list(),
});

// In TableBody
{clients?.map(client => (
  <TableRow key={client.id}>
    <TableCell>{client.name}</TableCell>
    <TableCell>{new Date(client.created_at).toLocaleDateString()}</TableCell>
    <TableCell className="gap-2">
      <Button variant="ghost" size="sm">Edit</Button>
      <Button variant="destructive" size="sm">Delete</Button>
    </TableCell>
  </TableRow>
))}
```

2. **Use in page:**

```tsx
// frontend/app/(staff)/clients/page.tsx
import { ClientList } from "@/components/client/ClientList";

export default function ClientsPage() {
  return <ClientList />;
}
```

## Example 2: Generate Form Component

```bash
python .agent/skills/frontend-component-generator/scripts/generate_component.py
```

**Prompts:**

```
Component Type: 2 (Form component)

Component name: ClientForm

Entity name: Client
```

**Generated file:**

`frontend/components/client/ClientForm.tsx`

```tsx
"use client";

import React from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  Form,
  FormField,
  FormItem,
  FormLabel,
  FormControl,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

const formSchema = z.object({
  name: z.string().min(1, "Name required"),
  // TODO: Add other fields
});

type FormData = z.infer<typeof formSchema>;

interface ClientFormProps {
  clientId?: number;
  onSuccess?: () => void;
}

export const ClientForm: React.FC<ClientFormProps> = ({
  clientId,
  onSuccess,
}) => {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      // TODO: Call service
      // if (clientId) {
      //   await clientService.update(clientId, data);
      // } else {
      //   await clientService.create(data);
      // }
      // onSuccess?.();
    } catch (error) {
      form.setError("root", { message: "Failed to save" });
    }
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      <FormField
        control={form.control}
        name="name"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Name</FormLabel>
            <FormControl>
              <Input placeholder="Enter name" {...field} />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* TODO: Add other fields */}

      <div className="flex gap-2">
        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? "Saving..." : "Save"}
        </Button>
        <Button type="button" variant="outline">
          Cancel
        </Button>
      </div>
    </form>
  );
};
```

## Implementation Steps

To complete the generated form:

```tsx
// Add validation schema
const formSchema = z.object({
  name: z.string().min(1, "Name required").max(255),
  industry: z.string().optional(),
  // Add other fields
});

// Add service call
const mutation = useMutation({
  mutationFn: (data: ClientCreate) => clientService.create(data),
  onSuccess: () => onSuccess?.(),
});

const onSubmit = async (data: FormData) => {
  mutation.mutate(data);
};

// Add field
<FormField
  control={form.control}
  name="industry"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Industry</FormLabel>
      <FormControl>
        <Input placeholder="e.g., Tech, Finance" {...field} />
      </FormControl>
    </FormItem>
  )}
/>
```

## Example 3: Generate Dialog Component

```bash
python .agent/skills/frontend-component-generator/scripts/generate_component.py
```

**Prompts:**

```
Component Type: 3 (Dialog component)

Component name: SelectClientDialog

Entity name: Client
```

**Generated:**

`frontend/components/client/SelectClientDialog.tsx`

```tsx
"use client";

import React from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

interface SelectClientDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSelect?: (client: any) => void;
}

export const SelectClientDialog: React.FC<SelectClientDialogProps> = ({
  open,
  onOpenChange,
  onSelect,
}) => {
  // TODO: useQuery to load clients
  // const { data: clients } = useQuery(...);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Select Client</DialogTitle>
        </DialogHeader>
        
        <div className="grid gap-2">
          {/* TODO: Map over clients and show selectable list */}
        </div>

        <div className="flex gap-2 justify-end">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};
```

## Example 4: Generate Custom Hook

```bash
python .agent/skills/frontend-component-generator/scripts/generate_component.py
```

**Prompts:**

```
Component Type: 4 (Custom hook)

Component name: useClients

Entity name: Client
```

**Generated:**

`frontend/lib/hooks/useClients.ts`

```tsx
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

/**
 * useClients Hook
 * 
 * Custom hook for managing Client data and mutations.
 * Handles:
 * - Loading states
 * - Error handling
 * - Cache invalidation
 * - Async operations
 */

interface UseClientsOptions {
  enabled?: boolean;
}

export function useClients(options: UseClientsOptions = {}) {
  const queryClient = useQueryClient();

  // TODO: Replace with actual service
  const listQuery = useQuery({
    queryKey: ["client"],
    queryFn: async () => {
      // return clientService.list();
      return [];
    },
    enabled: options.enabled,
  });

  const createMutation = useMutation({
    mutationFn: async (data) => {
      // return clientService.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["client"] });
    },
  });

  // ... update and delete mutations
  
  return {
    // Queries
    clients: listQuery.data,
    isLoading: listQuery.isLoading,
    error: listQuery.error,

    // Mutations
    create: createMutation.mutate,
    // ... other mutations
  };
}
```

## Integration Example

Using the generated components together:

```tsx
// app/(staff)/clients/page.tsx
"use client";

import { useState } from "react";
import { ClientList } from "@/components/client/ClientList";
import { ClientForm } from "@/components/client/ClientForm";
import { Button } from "@/components/ui/button";

export default function ClientsPage() {
  const [showForm, setShowForm] = useState(false);

  return (
    <div className="space-y-4">
      {showForm ? (
        <ClientForm 
          onSuccess={() => setShowForm(false)}
        />
      ) : (
        <clientList />
      )}
    </div>
  );
}
```

## Component Organization

After generating components:

```
frontend/
├── components/
│   └── client/
│       ├── ClientList.tsx         (generated)
│       ├── ClientForm.tsx         (generated)
│       ├── ClientCard.tsx         (hand-written detail)
│       └── SelectClientDialog.tsx (generated)
├── app/
│   └── (staff)/
│       └── clients/
│           ├── page.tsx           (list page)
│           ├── [id]/
│           │   └── page.tsx       (detail page)
│           └── new/
│               └── page.tsx       (create page)
└── lib/
    └── hooks/
        ├── useClients.ts          (generated)
        └── useClientForm.ts       (custom)
```

## Best Practices

✅ **Start with list** - Get data structure right first  
✅ **Then forms** - Add create/edit  
✅ **Then dialogs** - For selection/confirmation  
✅ **Extract hooks** - Reuse data logic  
✅ **Keep components small** - Single responsibility  
✅ **Use shadcn/ui** - Consistent design  
✅ **Use THEME** - No hardcoded colors  

❌ **Don't:**
- Hardcode API URLs
- Skip TypeScript types
- Put business logic in components
- Duplicate data fetching logic

## See Also

- `vertical-slice-generator` - Generates complete features
- `test-runner` - Test components with Jest/Vitest
- `progress-tracker` - Track UI development status
