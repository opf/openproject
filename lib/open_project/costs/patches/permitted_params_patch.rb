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
                                          {new_material_budget_item_attributes: [:units, :cost_type_id, :comments, :budget]},
                                          {new_labor_budget_item_attributes: [:hours, :user_id, :comments, :budget]},
                                          {existing_material_budget_item_attributes: [:units, :cost_type_id, :comments, :budget]},
                                          {existing_labor_budget_item_attributes: [:hours, :user_id, :comments, :budget]})
    end

    def cost_type
      params.require(:cost_type).permit(:name,
                                        :unit,
                                        :unit_plural,
                                        :default,
                                        { new_rate_attributes: [:valid_from, :rate] },
                                        { existing_rate_attributes: [:valid_from, :rate] })
    end

    def user_rates
      params.require(:user).permit({ new_rate_attributes: [:valid_from, :rate],
                                     existing_rate_attributes: [:valid_from, :rate] })
    end
  end
end

PermittedParams.send(:include, OpenProject::Costs::Patches::PermittedParamsPatch)
