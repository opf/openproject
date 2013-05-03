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
  end
end

PermittedParams.send(:include, OpenProject::Costs::Patches::PermittedParamsPatch)
