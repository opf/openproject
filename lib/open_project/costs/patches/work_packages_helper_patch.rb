require_dependency 'work_packages_helper'

module OpenProject::Costs::Patches::WorkPackagesHelperPatch
  def self.included(base) # :nodoc:
    base.class_eval do
      def cost_work_package_attributes(work_package)
        attributes = []

        attributes << work_package_show_table_row(:cost_object) do
                        work_package.cost_object ?
                          link_to_cost_object(work_package.cost_object) :
                           "-"
                      end
        if User.current.allowed_to?(:view_time_entries, @project) ||
           User.current.allowed_to?(:view_own_time_entries, @project)

          attributes << work_package_show_table_row(:spent_hours) do
                          #TODO: put inside controller or model
                          summed_hours = @time_entries.sum(&:hours)

                          summed_hours > 0 ?
                            link_to(l_hours(summed_hours), issue_time_entries_path(work_package)) :
                            "-"
                        end

        end

        attributes << work_package_show_table_row(:overall_costs) do
                        @overall_costs.nil? ?
                          "-" :
                          number_to_currency(@overall_costs)
                      end

        if User.current.allowed_to?(:view_cost_entries, @project) ||
           User.current.allowed_to?(:view_own_cost_entries, @project)

          attributes << work_package_show_table_row(:spent_units) do

                          summed_costs = summarized_cost_entries(@cost_entries)

                          #summed_costs > 0 ?
                            summed_costs# :
                          #  "-"
                        end
        end

        attributes
      end

      def work_package_show_attributes_with_costs(work_package)
        original = work_package_show_attributes_without_costs(work_package)

        if @project.module_enabled? :costs_module
          original_without_spent_time = original.reject{ |a| a.attribute == :spent_time }

          additions = cost_work_package_attributes(work_package)

          original_without_spent_time + additions
        else
          original
        end
      end

      alias_method_chain :work_package_show_attributes, :costs
    end
  end
end

WorkPackagesHelper.send(:include, OpenProject::Costs::Patches::WorkPackagesHelperPatch)
