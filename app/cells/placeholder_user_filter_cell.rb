class PlaceholderUserFilterCell < RailsCell
  include UsersHelper
  include ActionView::Helpers::FormOptionsHelper

  options :groups, :roles, :clear_url, :project

  class << self
    def filter(params)
      q = base_query.new

      filter_project q, params[:project_id]
      filter_name q, params[:name]
      filter_group q, params[:group_id]
      filter_role q, params[:role_id]

      q.results
    end

    def filtered?(params)
      %i(name group_id role_id).any? { |name| params[name].present? }
    end

    def filter_name(query, name)
      if name.present?
        query.where(:any_name_attribute, '~', name)
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
      Queries::PlaceholderUsers::PlaceholderUserQuery
    end
  end

  # INSTANCE METHODS:

  def filter_path
    placeholder_users_path
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
end
