require_dependency 'permitted_params'

module OpenProject::Costs::Patches::PermittedParamsPatch
  def self.included(base) # :nodoc:

    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def cost_entry
      params.require(:cost_entry).permit(:comments,
                                         :units,
                                         :overridden_costs,
                                         :spent_on)
    end

    def cost_object
      params.require(:cost_object).permit(:subject,
                                          :description,
                                          :fixed_date,
                                          :project_manager_signoff,
                                          :client_signoff)
    end

    def cost_type
      params.require(:cost_type).permit(:name,
                                        :unit,
                                        :unit_plural,
                                        :default,
                                        :new_rate_attributes,
                                        :existing_rate_attributes)
    end

    def labor_budget_item
      params.require(:labor_budget_item).permit(:hours,
                                                :comments,
                                                :budget,
                                                :user_id)
    end

    def material_budget_item
      params.require(:material_budget_item).permit(:units,
                                                   :comments,
                                                   :budget,
                                                   :cost_type,
                                                   :cost_type_id)
    end

    def rate
      params.require(:rate).permit(:rate,
                                   :project,
                                   :valid_from)
    end
  end
end

PermittedParams.send(:include, OpenProject::Costs::Patches::PermittedParamsPatch)
