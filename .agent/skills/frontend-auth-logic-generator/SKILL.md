---
name: frontend-auth-logic-generator
description: Generates the specialized Next.js authentication layer (AuthContext, ProtectedRoute, useAuth) using the project's httpOnly cookie strategy.
---

# Frontend Auth Logic Generator

This skill sets up the core authentication state management on the frontend, standardizing on the `httpOnly` cookie strategy.

## When to use this skill
- Setting up a new client or staff portal.
- Refactoring from localStorage/Bearer tokens to Secure Cookies.
- Adding complex multi-permission route protection.

## How to use this skill

### Step 1: Auth Context
Create `frontend/lib/auth/AuthContext.tsx`.
- Behavior: Fetches `/api/v1/auth/me` on mount.
- State: Stores the `User` object and `isAuthenticated` status.
- Logic: No manual token management; relies on browser cookies.

### Step 2: Custom Hook
Create `frontend/lib/auth/useAuth.ts`.
- Exports: `user`, `login`, `logout`, `hasPermission`.

### Step 3: API Client Integration
Configure `frontend/lib/api-client.ts`.
- Set `withCredentials: true` globally.
- Implement a 401 interceptor that clears the AuthContext and redirects to `/login`.

### Step 4: Protected Routes
Create `frontend/components/auth/ProtectedRoute.tsx`.
- Function: Wraps pages to prevent unauthorized access.
- Prop: `requiredPermission` (optional) to check specific RBAC scopes.
- Branding: Uses the "Deep Green" and "Purple" atmospheric loading state.

## Success Criteria
- Authentication state is shared across the entire App Router.
- Protected routes redirect correctly without "flickering".
- No JWT or sensitive tokens are visible in the browser's Local Storage.
