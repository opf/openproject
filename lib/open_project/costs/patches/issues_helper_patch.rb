require_dependency 'issues_helper'

module OpenProject::Costs::Patches::IssuesHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      def summarized_cost_entries(cost_entries, create_link=true)
        last_cost_type = ""

        return "-" if cost_entries.blank?
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
            str_array << link_to(txt, { :controller => 'costlog',
                                        :action => 'index',
                                        :project_id => @issue.project,
                                        :issue_id => @issue,
                                        :cost_type_id => k },
                                       { :title => k.name })
          else
            str_array << "<span title=\"#{h(k.name)}\">#{txt}</span>"
          end
        end
        str_array.join(", ").html_safe
      end

      def cost_issues_attributes
        attributes = []

        object_value = if @issue.cost_object.nil?
                         "-"
                       else
                         link_to_cost_object(@issue.cost_object)
                       end

        attributes << [CostObject.model_name.human, object_value]

        if User.current.allowed_to?(:view_time_entries, @project) ||
           User.current.allowed_to?(:view_own_time_entries, @project)

           value = @issue.spent_hours > 0 ?
                     link_to(l_hours(@issue.spent_hours), { :controller => 'timelog',
                                                            :action => 'index',
                                                            :issue_id => @issue}) :
                     "-"

           attributes << [Issue.human_attribute_name(:spent_hours), value]
        end

        unless @overall_costs.nil?
          attributes << [Issue.human_attribute_name(:overall_costs), number_to_currency(@overall_costs)]
        end


        if User.current.allowed_to?(:view_cost_entries, @project) ||
           User.current.allowed_to?(:view_own_cost_entries, @project)

          attributes << [Issue.human_attribute_name(:spent_units), summarized_cost_entries(@cost_entries)]
        end

        attributes
      end
    end
  end

  module InstanceMethods

  end
end

IssuesHelper.send(:include, OpenProject::Costs::Patches::IssuesHelperPatch)
