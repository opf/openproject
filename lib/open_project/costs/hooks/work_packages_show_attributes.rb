module OpenProject::Costs::Hooks
  class WorkPackagesShowHook < Redmine::Hook::ViewListener
    #include ActionView::Helpers::TagHelper
    #include ActionView::Helpers::NumberHelper
    #include ActionView::Helpers::UrlHelper
    #include ActionView::Helpers::TextHelper
    include ActionView::Context
    include WorkPackagesHelper

    def work_packages_show_attributes(context = {})
      @work_package = context[:work_package]
      @project = context[:project]
      attributes = context[:attributes]

      return unless @project.module_enabled? :costs_module

      attributes.reject!{ |a| a.attribute == :spent_time }

      attributes << cost_work_package_attributes(@work_package)
      attributes.flatten!

      attributes
    end

    private

    def cost_entries
      @cost_entries ||= @work_package.cost_entries.visible(User.current, @work_package.project)
    end

    def material_costs
      return @material_costs if @material_costs

      cost_entries_with_rate = cost_entries.select{|c| c.costs_visible_by?(User.current)}
      @material_costs = cost_entries_with_rate.blank? ? nil : cost_entries_with_rate.collect(&:real_costs).sum
    end

    def time_entries
      @time_entries ||= @work_package.time_entries.visible(User.current, @work_package.project)
    end

    def labor_costs
      return @labor_costs if @labor_costs

      time_entries_with_rate = time_entries.select{|c| c.costs_visible_by?(User.current)}
      @labor_costs = time_entries_with_rate.blank? ? nil : time_entries_with_rate.collect(&:real_costs).sum
    end

    def overall_costs
      return @overall_costs if @overall_costs

      unless material_costs.nil? && @labor_costs.nil?
        @overall_costs = 0
        @overall_costs += material_costs unless material_costs.nil?
        @overall_costs += labor_costs unless labor_costs.nil?
      else
        @overall_costs = nil
      end
    end

    def cost_work_package_attributes(work_package)
      attributes = []

      attributes << work_package_show_table_row(:cost_object) do
        work_package.cost_object ?
          link_to_cost_object(work_package.cost_object) :
          empty_element_tag
      end
      if User.current.allowed_to?(:view_time_entries, @project) ||
        User.current.allowed_to?(:view_own_time_entries, @project)

        attributes << work_package_show_table_row(:spent_hours) do
          # TODO: put inside controller or model
          summed_hours = time_entries.sum(&:hours)

          summed_hours > 0 ?
            link_to(l_hours(summed_hours), work_package_time_entries_path(work_package)) :
            empty_element_tag
        end

      end
      attributes << work_package_show_table_row(:overall_costs) do
        overall_costs.nil? ?
          empty_element_tag :
          number_to_currency(overall_costs)
      end

      if User.current.allowed_to?(:view_cost_entries, @project) ||
        User.current.allowed_to?(:view_own_cost_entries, @project)

        attributes << work_package_show_table_row(:spent_units) do
          summarized_cost_entries(cost_entries, work_package)
        end
      end

      attributes
    end

    def summarized_cost_entries(cost_entries, work_package, create_link=true)
      last_cost_type = ""

      return empty_element_tag if cost_entries.blank?
      result = cost_entries.sort_by(&:id).inject(Hash.new) do |result, entry|
        if entry.cost_type == last_cost_type
          result[last_cost_type][:units] += entry.units
        else
          last_cost_type = entry.cost_type

          result[last_cost_type] = {}
          result[last_cost_type][:units] = entry.units
          result[last_cost_type][:unit] = entry.cost_type.unit
          result[last_cost_type][:unit_plural] = entry.cost_type.unit_plural
        end
        result
      end

      str_array = []
      result.each do |k, v|
        txt = pluralize(v[:units], v[:unit], v[:unit_plural])
        if create_link
          # TODO why does this have project_id, work_package_id and cost_type_id params?
          str_array << link_to(txt, { :controller => '/costlog',
                                      :action => 'index',
                                      :project_id => work_package.project,
                                      :work_package_id => work_package,
                                      :cost_type_id => k },
                                      { :title => k.name })
        else
          str_array << "<span title=\"#{h(k.name)}\">#{txt}</span>"
        end
      end
      str_array.join(", ").html_safe
    end
  end
end
