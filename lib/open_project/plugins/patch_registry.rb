module OpenProject::Plugins
  module PatchRegistry
    def self.register(target, patch)
      #patches[target] << patch

      ActiveSupport.on_load(target) do
        require_dependency patch
        constant = patch.camelcase.constantize

        target.to_s.camelcase.constantize.send(:include, constant)
      end
    end

    protected

    def self.patches
      @patches ||= Hash.new do |h, k|
        h[k] = []
      end
    end
  end
end
