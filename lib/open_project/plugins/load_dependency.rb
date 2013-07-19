module OpenProject::Plugins
  module LoadDependency
    def self.register(target, *dependencies)

      ActiveSupport.on_load(target) do
        dependencies.each do |dependency|
          require_dependency dependency
        end
      end

    end
  end
end
