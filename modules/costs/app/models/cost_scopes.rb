module CostScopes
  def self.included(base_module)
    base_module.class_eval do
      def self.extended(base_class)
        base_class.class_eval do
          def self.visible(*args)
            user = args.first || User.current
            with_visible_entries_on self, user:, project: args[1]
          end

          def self.visible_costs(*args)
            user = args.first || User.current
            with_visible_costs_on self, user:, project: args[1]
          end
        end
      end
    end
  end

  def view_allowed_entries_permission
    raise NotImplementedError
  end

  def view_allowed_own_entries_permission
    raise NotImplementedError
  end

  def view_rates_permissions
    raise NotImplementedError
  end

  def with_visible_costs_on(scope, user: User.current, project: nil)
    with_visible_entries = with_visible_entries_on(scope, user:, project:)
    with_visible_rates_on with_visible_entries, user:
  end

  def with_visible_entries_on(scope, user: User.current, project: nil)
    table = arel_table

    visible_scope = scope.where(
      view_or_view_own(table, view_allowed_entries_permission, view_allowed_own_entries_permission, user)
    )

    if project
      visible_scope.where(project_id: project.id)
    else
      visible_scope
    end
  end

  def view_or_view_own(table, allowed_permission, allowed_own_permission, user) # rubocop:disable Metrics/AbcSize
    project_allowed_scope = table[:project_id].in(Project.allowed_to(user, allowed_permission).select(:id).arel)

    # We allow some of the `_own_` permissions on the WorkPackage, but others only on the project,
    # so we need to figure out the correct scope to use
    wp_scoped_permission = Authorization.permissions_for(allowed_own_permission).any?(&:work_package?)

    if wp_scoped_permission
      project_allowed_scope.or(
        table[:work_package_id]
        .in(WorkPackage.allowed_to(user, allowed_own_permission).select(:id).arel)
        .and(table[:user_id].eq(user.id))
      )
    else
      project_allowed_scope.or(
        table[:project_id]
        .in(Project.allowed_to(user, allowed_own_permission).select(:id).arel)
        .and(table[:user_id].eq(user.id))
      )
    end
  end

  def with_visible_rates_on(scope, user: User.current)
    table = arel_table
    view_allowed = Project.allowed_to(user, view_rates_permissions).select(:id)

    scope.where(table[:project_id].in(view_allowed.arel))
  end
end
