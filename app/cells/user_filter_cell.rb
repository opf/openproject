class UserFilterCell < RailsCell
  include UsersHelper
  include ActionView::Helpers::FormOptionsHelper

  options :groups, :status, :roles, :clear_url, :project

  class << self
    def filter(params)
      q = base_query.new

      filter_project q, params[:project_id]
      filter_name q, params[:name]
      filter_status q, status_param(params)
      filter_group q, params[:group_id]
      filter_role q, params[:role_id]

      q.results
    end

    def filtered?(params)
      %i(name status group_id role_id).any? { |name| params[name].present? }
    end

    ##
    # Returns the selected status from the parameters
    # or the default status to be filtered by (all)
    # if no status is given.
    def status_param(params)
      params[:status].presence || 'all'
    end

    def filter_name(query, name)
      if name.present?
        query.where(:any_name_attribute, '~', name)
      end
    end

    def filter_status(query, status)
      return unless status && status != 'all'

      case status
      when 'blocked'
        query.where(:blocked, '=', :blocked)
      when 'active'
        query.where(:status, '=', status.to_sym)
        query.where(:blocked, '!', :blocked)
      else
        query.where(:status, '=', status.to_sym)
      end
    end

    def filter_group(query, group_id)
      if group_id.present?
        query.where(:group, '=', group_id)
      end
    end

    def filter_role(query, role_id)
      if role_id.present?
        query.where(:role_id, '=', role_id)
      end
    end

    def filter_project(query, project_id)
      if project_id.present?
        query.where(:project_id, '=', project_id)
      end
    end

    def base_query
      Queries::Users::UserQuery
    end
  end

  # INSTANCE METHODS:

  def filter_path
    users_path
  end

  def initially_visible?
    true
  end

  def has_close_icon?
    false
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
