#!/usr/bin/env python3
"""
Frontend Component Generator - Creates React components with TypeScript and styling.

This script provides an interactive interface for generating React components:
- List components with tables/cards
- Form components with validation
- Detail view components
- Dialog/modal components
- Custom hooks and services

Usage:
    python generate_component.py

Options:
    1. Create list component (table/cards)
    2. Create form component (create/edit)
    3. Create detail component
    4. Create dialog component
    5. Create custom hook

Output:
    - Generated .tsx file with TypeScript
    - Props interface
    - Tailwind CSS styling
    - shadcn/ui components
    - API integration scaffolding
"""

import re
from pathlib import Path
from typing import Optional


def find_frontend_path() -> Optional[Path]:
    """Find frontend directory."""
    current = Path(__file__)
    while current != current.parent:
        if (current / "frontend" / "components").exists():
            return current / "frontend"
        current = current.parent
    return None


def generate_list_component(name: str, entity: str) -> str:
    """Generate a list component."""
    camel_entity = entity[0].lower() + entity[1:]  # clientCompany
    
    return f'''\"use client\";

import React, {{ useState }} from \"react\";
import {{ useQuery }} from \"@tanstack/react-query\";
import {{
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
}} from \"@/components/ui/table\";
import {{ Button }} from \"@/components/ui/button\";
import {{ THEME }} from \"@/styles/theme\";

/**
 * {name} Component
 * 
 * Displays a list of {entity} items in a table format.
 * Features:
 * - Sorting
 * - Filtering
 * - Pagination
 * - Actions (edit, delete)
 */

interface {entity} {{
  id: number;
  name: string;
  created_at: string;
  // TODO: Add other fields
}}

export const {name}: React.FC = () => {{
  const [page, setPage] = useState(1);
  
  // TODO: Import service
  // const {{ data, isLoading, error }} = useQuery({{
  //   queryKey: [\"{camel_entity}\", page],
  //   queryFn: () => {entity.lower()}Service.list({{ page }}),
  // }});

  // if (isLoading) return <div>Loading...</div>;
  // if (error) return <div>Error loading {entity.lower()}</div>;

  return (
    <div className=\"space-y-4\">
      <div className=\"flex justify-between items-center\">
        <h1 className=\"text-2xl font-bold\">{entity}s</h1>
        <Button>Create {entity}</Button>
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
          {{/* TODO: Map over {camel_entity}s */}}
          {{/* {{
            {camel_entity}s?.map(({camel_entity}) => (
              <TableRow key={{{camel_entity}.id}}>
                <TableCell>{{{camel_entity}.name}}</TableCell>
                <TableCell>{{{camel_entity}.created_at}}</TableCell>
                <TableCell className=\"gap-2\">
                  <Button variant=\"ghost\" size=\"sm\">Edit</Button>
                  <Button variant=\"destructive\" size=\"sm\">Delete</Button>
                </TableCell>
              </TableRow>
            ))
          }} */}}
        </TableBody>
      </Table>
    </div>
  );
}};
'''


def generate_form_component(name: str, entity: str) -> str:
    """Generate a form component."""
    return f'''\"use client\";

import React from \"react\";
import {{ useForm }} from \"react-hook-form\";
import {{ zodResolver }} from \"@hookform/resolvers/zod\";
import {{ z }} from \"zod\";
import {{
  Form,
  FormField,
  FormItem,
  FormLabel,
  FormControl,
  FormMessage,
}} from \"@/components/ui/form\";
import {{ Input }} from \"@/components/ui/input\";
import {{ Button }} from \"@/components/ui/button\";

/**
 * {name} Component
 * 
 * Form for creating/editing {entity} records.
 * Features:
 * - React Hook Form integration
 * - Zod validation
 * - Error handling
 * - Submit loading state
 */

const formSchema = z.object({{
  name: z.string().min(1, \"Name required\"),
  // TODO: Add other fields
}});

type FormData = z.infer<typeof formSchema>;

interface {name}Props {{
  {entity.lower()}Id?: number;
  onSuccess?: () => void;
}}

export const {name}: React.FC<{name}Props> = ({{
  {entity.lower()}Id,
  onSuccess,
}}) => {{
  const form = useForm<FormData>({{
    resolver: zodResolver(formSchema),
  }});

  const onSubmit = async (data: FormData) => {{
    try {{
      // TODO: Call service
      // if ({entity.lower()}Id) {{
      //   await {entity.lower()}Service.update({entity.lower()}Id, data);
      // }} else {{
      //   await {entity.lower()}Service.create(data);
      // }}
      // onSuccess?.();
    }} catch (error) {{
      form.setError(\"root\", {{ message: \"Failed to save\" }});
    }}
  }};

  return (
    <form onSubmit={{form.handleSubmit(onSubmit)}} className=\"space-y-4\">
      <FormField
        control={{form.control}}
        name=\"name\"
        render={{({{ field }}) => (
          <FormItem>
            <FormLabel>Name</FormLabel>
            <FormControl>
              <Input placeholder=\"Enter name\" {{...field}} />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}}
      />

      {{/* TODO: Add other fields */}}

      <div className=\"flex gap-2\">
        <Button type=\"submit\" disabled={{form.formState.isSubmitting}}>
          {{form.formState.isSubmitting ? \"Saving...\" : \"Save\"}}
        </Button>
        <Button type=\"button\" variant=\"outline\">
          Cancel
        </Button>
      </div>
    </form>
  );
}};
'''


def generate_dialog_component(name: str, entity: str) -> str:
    """Generate a dialog component."""
    return f'''\"use client\";

import React from \"react\";
import {{ useQuery }} from \"@tanstack/react-query\";
import {{
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
}} from \"@/components/ui/dialog\";
import {{ Button }} from \"@/components/ui/button\";

/**
 * {name} Component
 * 
 * Dialog for selecting/creating {entity} records.
 * Modal overlay with list or form inside.
 */

interface {name}Props {{
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSelect?: ({entity.lower()}: any) => void;
}}

export const {name}: React.FC<{name}Props> = ({{
  open,
  onOpenChange,
  onSelect,
}}) => {{
  // TODO: useQuery to load {entity} list
  // const {{ data: {entity.lower()}s }} = useQuery(...);

  return (
    <Dialog open={{open}} onOpenChange={{onOpenChange}}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Select {entity}</DialogTitle>
        </DialogHeader>
        
        <div className=\"grid gap-2\">
          {{/* TODO: Map over {entity.lower()}s and show selectable list */}}
        </div>

        <div className=\"flex gap-2 justify-end\">
          <Button variant=\"outline\" onClick={{() => onOpenChange(false)}}>
            Cancel
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}};
'''


def generate_hook(name: str, entity: str) -> str:
    """Generate a custom hook."""
    hook_name = f"use{name.replace('use', '')}"
    
    return f'''import {{ useQuery, useMutation, useQueryClient }} from \"@tanstack/react-query\";

/**
 * {hook_name} Hook
 * 
 * Custom hook for managing {entity} data and mutations.
 * Handles:
 * - Loading states
 * - Error handling
 * - Cache invalidation
 * - Async operations
 */

interface Use{name.replace('use', '')}Options {{
  enabled?: boolean;
}}

export function {hook_name}(options: Use{name.replace('use', '')}Options = {{}}) {{
  const queryClient = useQueryClient();

  // TODO: Replace with actual service
  const listQuery = useQuery({{
    queryKey: [\"{entity.lower()}\"],
    queryFn: async () => {{
      // return {entity.lower()}Service.list();
      return [];
    }},
    enabled: options.enabled,
  }});

  const createMutation = useMutation({{
    mutationFn: async (data) => {{
      // return {entity.lower()}Service.create(data);
    }},
    onSuccess: () => {{
      queryClient.invalidateQueries({{ queryKey: [\"{entity.lower()}\"] }});
    }},
  }});

  const updateMutation = useMutation({{
    mutationFn: async ({{ id, data }}) => {{
      // return {entity.lower()}Service.update(id, data);
    }},
    onSuccess: () => {{
      queryClient.invalidateQueries({{ queryKey: [\"{entity.lower()}\"] }});
    }},
  }});

  const deleteMutation = useMutation({{
    mutationFn: async (id) => {{
      // return {entity.lower()}Service.delete(id);
    }},
    onSuccess: () => {{
      queryClient.invalidateQueries({{ queryKey: [\"{entity.lower()}\"] }});
    }},
  }});

  return {{
    // Queries
    {entity.lower()}s: listQuery.data,
    isLoading: listQuery.isLoading,
    error: listQuery.error,

    // Mutations
    create: createMutation.mutate,
    update: updateMutation.mutate,
    delete: deleteMutation.mutate,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  }};
}}
'''


def create_component() -> None:
    """Interactive component creation."""
    frontend_path = find_frontend_path()
    if not frontend_path:
        print("ERROR: Frontend path not found")
        return
    
    print("\nComponent Type:")
    print("  1. List component")
    print("  2. Form component")
    print("  3. Dialog component")
    print("  4. Custom hook")
    
    choice = input("Select (1-4): ").strip()
    
    name = input("Component name (PascalCase): ").strip()
    entity = input("Entity name (e.g., Client): ").strip()
    
    if choice == "1":
        code = generate_list_component(name, entity)
        ext = ".tsx"
    elif choice == "2":
        code = generate_form_component(name, entity)
        ext = ".tsx"
    elif choice == "3":
        code = generate_dialog_component(name, entity)
        ext = ".tsx"
    elif choice == "4":
        code = generate_hook(name, entity)
        ext = ".ts"
    else:
        print("Invalid choice")
        return
    
    # Determine output path
    if ext == ".tsx":
        components_path = frontend_path / "components" / entity.lower()
        components_path.mkdir(parents=True, exist_ok=True)
        output_file = components_path / f"{name}{ext}"
    else:
        hooks_path = frontend_path / "lib" / "hooks"
        hooks_path.mkdir(parents=True, exist_ok=True)
        output_file = hooks_path / f"{name}{ext}"
    
    output_file.write_text(code)
    
    print(f"\n✅ Created: {output_file}")
    print("\nNext steps:")
    print("  1. Review generated code")
    print("  2. Update TODO comments with actual logic")
    print("  3. Import and use in your pages")
    print("  4. Test with real API")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║   Frontend Component Generator - ESG Sustainify React           ║
║                                                                ║
║  Generate TypeScript React components with scaffolding         ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    while True:
        print("\nOptions:")
        print("  1. Create component")
        print("  2. Exit")
        
        choice = input("\nSelect (1-2): ").strip()
        
        if choice == "1":
            create_component()
        elif choice == "2":
            print("Goodbye!")
            break
        else:
            print("Invalid choice")
