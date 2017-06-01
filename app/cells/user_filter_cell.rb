class UserFilterCell < RailsCell
  include UsersHelper
  include ActionView::Helpers::FormOptionsHelper

  options :groups, :status, :roles, :clear_url, :project

  class << self
    def filter(query, params)
      [query]
        .map { |q| filter_name q, params[:name] }
        .map { |q| filter_status q, status_param(params) }
        .map { |q| filter_group q, params[:group_id] }
        .map { |q| filter_role q, params[:role_id] }
        .first
    end

    def is_filtered(params)
      [:name, :status, :group_id, :role_id].any? { |name| params[name].present? }
    end

    ##
    # Returns the selected status from the parameters
    # or the default status to be filtered by (active)
    # if no status is given.
    def status_param(params)
      params[:status].presence || User::STATUSES[:active]
    end

    def filter_name(query, name)
      if name.present?
        query.where(filter_name_condition, name: "%#{name.downcase}%")
      else
        query
      end
    end

    def filter_name_condition
      filter_name_columns
        .map { |col| "LOWER(#{col}) LIKE :name" }
        .join(" OR ")
    end

    def filter_name_columns
      [:lastname, :firstname, :mail, :login]
    end

    def filter_status(query, status)
      q = specific_filter_status(query, status) || query
      q = User.create_blocked_scope q, false if status.to_i == User::STATUSES[:active]

      q.where("status <> :builtin", builtin: User::STATUSES[:builtin])
    end

    def specific_filter_status(query, status)
      if status.present?
        if status == "blocked"
          User.create_blocked_scope query, true
        elsif status != "all"
          query.where(filter_status_condition, status: status.to_i)
        end
      end
    end

    def filter_status_condition
      "status = :status"
    end

    def filter_group(query, group_id)
      if group_id.present?
        join_group_users(query).where(filter_group_condition, group_id: group_id.to_i)
      else
        query
      end
    end

    def join_group_users(query)
      query.joins("LEFT JOIN group_users ON group_users.user_id = users.id")
    end

    def filter_group_condition
      "group_id = :group_id"
    end

    def filter_role(query, role_id)
      if role_id.present?
        join_role(query).where(filter_role_condition, role_id: role_id.to_i)
      else
        query
      end
    end

    def filter_role_condition
      "role_id = :role_id"
    end

    def join_role(query)
      query.joins(members: { member_roles: :role })
    end
  end

  # INSTANCE METHODS:

  def initially_visible?
    true
  end

  def params
    model
  end

  def user_status_options
    users_status_options_for_select status, extra: extra_user_status_options
  end

  def extra_user_status_options
    {}
  end
end
