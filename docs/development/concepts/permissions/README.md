---
sidebar_navigation:
  title: Permissions
description: Get an overview of how roles and permissions are handled in the OpenProject application code
robots: index, follow
keywords: permissions, roles, RBAC
---

# Development concept: Permissions

OpenProject is very flexible when it comes to authorization and granting permissions to users. The OpenProject application uses a Role-based access control (RBAC) approach to grant individual users permissions to projects.

With RBAC, the application defines a set of roles that users and groups can be individually assigned to within the scope of a project or globally. In OpenProject, the roles and permissions contained within are freely configurable. There can be an arbitrary number of roles defined.



## Key takeaways

*Permissions in OpenProject...*

- use the Role-based access control (RBAC) approach to allow fine-grained access to authorized resources
- are assigned to users and groups through roles on a per-project or global level
- are often communicated to the frontend through the presence of action links in HAL resources



## Definition of roles

Roles in OpenProject can be defined in the global administration. If you would read about roles from a user experience, please see the [Roles & Permissions guide](../../../system-admin-guide/users-permissions/roles-permissions/#roles-and-permissions)

In the backend, roles are a Rails model  [`Role`](https://github.com/opf/openproject/tree/dev/app/models/role.rb) that holds a set of permissions associated in a `RolePermission` lookup table.

There are multiple types of roles:

- [Global roles](https://github.com/opf/openproject/tree/dev/modules/global_roles/app/models/global_role.rb) that are granted to user on a global level, i.e. they are not assigned per project. They can contain the permissions to e.g., *Create new projects*. *Please note, that the global_roles module is a relict of the past and is to be merged into the core*
- *Non member* roles that is a special role that applies to any _authenticated_ user and all public projects that this user is not a member of. On the OpenProject community, it is configured to grant non-members of the public projects, i.e. all logged in users, the permissions *Add forum posts* and *Create new work package*.
- *Anonymous* roles that is a special role, similar to the *non member* role but applying to non-authenticated users.
- All other roles, which are saved in the database and contain a user-defined set of permissions that this role will grant.

**Surprisingly, when looking up permissions, the non member role is always factored in, even it the user does have other roles within the project as well. That means that if the user has a role in a project not granting "Create new work package", but the non member role is granting the permission, the user will in effect have that permission.**

In the following screenshot, you can see the builtin, non-deletable roles *Non member* and *Anonymous*, as well as three additional, user-created roles.

![Overview of some of the roles](roles-administration.png)



Scrolling through the list of available permissions, you will begin to see the flexibility (and complexity) of the potential user permissions that are available:

![Overview of available permissions in a regular role](roles-permissions-overview.gif)



## Definition of Permissions

The permissions are defined in two places:

1. The core [`config/initializers/permissions.rb`](https://github.com/opf/openproject/tree/dev/config/initializers/permissions.rb) initializer file. It defines the available project modules and its associated permissions
2. Module permissions defined in the `engine.rb` of modules under `module/` folder. For example, the definitions for budgets are defined in[`modules/budgets/lib/budgets/engine.rb`](https://github.com/opf/openproject/tree/dev/modules/budgets/lib/budgets/engine.rb).

These definitions determine the name of the permission and the Rails controller actions that are this permission unlocks. In some cases, the permissions do not define a controller action and then is only used for authorization checks in contracts. 



## Checking of permissions in Backend

The way a developer can check for permissions obviously depends on whether the backend or frontend is doing the check. We will go through some of the possible ways to check for authorization.

### Desired layer

While not the case throughout the application, permissions:
 * should be checked in the Contracts whenever wanting to change a record. This also includes the values that are assignable (e.g. which users are available to become assignee of a work package)
 * should be applied to scopes whenever fetching a set of records. Even when only fetching an individual record it is best to apply a scope checking the visibility before the `find` instead of fetching the record first and then check for the visibility.
 * needs unfortunately to be checked in the view/representers whenever an attribute is visible for one group of users but not for another.
 * should **not** be checked in the controller layer unless an explicit 403 response needs to be returned.

### Controller `before_action`

If the permission should be tested for a specific controller action, it will suffice to call the `before_action :authorize` to handle authorization.

As an example, the permissions `:manage_members`,  `:view_members` is defined as follows:

```ruby
permission :manage_members, { members: %i[index new create update destroy autocomplete_for_member] }
permission :view_members, { members: [:index] }
```

This means if a user has only the `:view_members` permission, the `authorize` check in the [`MembersController`](https://github.com/opf/openproject/tree/dev/app/controllers/members_controller.rb) will allow the user to pass through for the `index` action (Overview of the members), but not the CRUD actions. These will only pass if the user has the `manage_members` (or both) permissions.

### API Endpoints

Given that the API endpoints are controllers as well, the permission checks are handled similarly, to protect an endpoint against unauthorized access, a before block is defined e.g. like this:

```ruby
after_validation do
  authorize :manage_members, global: true
end
```

However, for most end points, this does not need to be and should not be done on the controller level. Endpoints that are contract backed, which is true for most of the create, update and delete end points, the permissions, including access to a resource is checked within the contracts. The index end points are mostly protected by their queries relying on a `visible` scope which factors the permissions into the SQL fetching the records. That way, an empty collection is returned if the user lacks permission. If an explicit 403 needs to be returned, though, the explicit permission check in the endpoint is required for now. The show endpoints need to be protected akin to how the index actions. The `visible` scope is applied (e.g. `WorkPackage.visible.find(5)`). This will lead to a `RecordNotFound` exception being thrown when the permission is lacking. That exception is then handled transparently by returning a 404. We return 404 instead of 403 to not reveal the existence of a record.   

### Scopes

When a set of records is to be returned, e.g. for an index action, it is best to limit the returned result set to the records the user is allowed to see. To avoid having to apply the permission check after the records have been fetched and instantiated, which is costly, it is best to limit the records in the sql right away. As there are a couple of different scenarios for fetching records, there are a couple of matching scopes defined:

| Schenario | Scope | Example |
|---------- | ------| ------ |
| All projects a user is allowed a permission in | `Authorization.projects(permission, user)` | `Authorization.projects(:view_work_packages, User.current)` |
| All users granted a permission in a project | `Authorization.users(permission, project)` | `Authorization.users(:view_work_packages, project)` |
| All roles a user has in a project or globally | `Authorization.roles(user, project = nil)` | `Authorization.roles(User.current, project)`, `Authorization.roles(User.current)` |

Most of the time, a developer will not witness those queries as they are the embedded deeply within the existing scopes. E.g. the `visible` scopes defined for most AR models, under the hood rely on `Authorization.projects(permission, user)` by checking that the `project_id` attribute of the record is within that set of projects.

### Explicitly testing for permissions

If you have a user and a project, you can explicitly ask for a permission like so:

```ruby
project = Project.find_by(name: 'My project')
user = User.find_by(login: 'foobar')

user.allowed_to?(:view_members, project) # true or false
```

The same is true for permissions outside a project using`user.allowed_to_globally?(permission)`. This will either test a global permission such as `:add_project` or return `true` whenever the user has such a permission in any project.



## Checking of permissions in Frontend

In the frontend, we have to rely on the API to tell us what actions the user is allowed to do. With [`HAL+JSON resources`](../hal-resources), we can do that by checking for the presence or absence of an action link in responses.

For example, if the user has the permission to create work packages in the OpenProject project on the community, [the collection response of the work packages API](https://community.openproject.com/api/v3/projects/openproject/work_packages?pageSize=0) of it will contain a link `createWorkPackage` that contains the link to the create form API endpoint.

To check these links, one can use the [`ModelAuthService`](https://github.com/opf/openproject/tree/dev/frontend/src/app/modules/common/model-auth/model-auth.service.ts) that gets initialized with the resources being loaded:

```typescript
const modelAuth = injector.get(ModelAuthService);
modelAuth.initModelAuth('work_packages', { createWorkPackage: () => 'foo' });

modelAuth.can('work_packages', 'createWorkPackage'); // true
modelAuth.can('work_packages', 'someOtherAction'); // false
```

The service doesn't care for what's inside the links but just looks for their presence.

The fact that permissions are implicitly checked through links has the advantage that the frontend doesn't need to care about whether a functionality has been disabled in the project (i.e., the project module is not enabled there) or if the user has no permission to access it.

The downside to this approach is that it is impossible to check a multitude of permissions upfront without loading the necessary requests. In some cases, we thus load requests just for the sake of permission testing, even though we do not depend on the API response itself.