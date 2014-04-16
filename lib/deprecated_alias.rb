  module DeprecatedAlias
    def deprecated_alias(old_method, new_method)
      define_method(old_method) do |*args, &block|
        ActiveSupport::Deprecation.warn "#{old_method} is deprecated and will be removed in a future OpenProject version. Please use #{new_method} instead.", caller
        send(new_method, *args, &block)
      end
    end
  end
