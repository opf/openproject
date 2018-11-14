module CostScopes
  def self.included(base_module)
    base_module.class_eval do
      def self.extended(base_class)
        base_class.class_eval do

          def self.visible(*args)
            user = args.first || User.current
            with_visible_entries_on self, user: user, project: args[1]
          end

          def self.visible_costs(*args)
            user = args.first || User.current
            with_visible_costs_on self, user: user, project: args[1]
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
    with_visible_entries = with_visible_entries_on(scope, user: user, project: project)
    with_visible_rates_on with_visible_entries, user: user
  end

  def with_visible_entries_on(scope, user: User.current, project: nil)
    table = self.arel_table

    view_allowed = Project.allowed_to(user, view_allowed_entries_permission).select(:id)
    view_own_allowed = Project.allowed_to(user, view_allowed_own_entries_permission).select(:id)
    visible_scope = scope.where view_or_view_own(table, view_allowed, view_own_allowed, user)

    if project
      visible_scope.where(project_id: project.id)
    else
      visible_scope
    end
  end

  def view_or_view_own(table, view_allowed, view_own_allowed, user)
    table[:project_id]
      .in(view_allowed.arel)
      .or(
        table[:project_id]
          .in(view_own_allowed.arel)
          .and(table[:user_id].eq(user.id)))
  end

  def with_visible_rates_on(scope, user: User.current)
    table = self.arel_table
    view_allowed = Project.allowed_to(user, view_rates_permissions).select(:id)

    scope.where(table[:project_id].in(view_allowed.arel))
  end
end
