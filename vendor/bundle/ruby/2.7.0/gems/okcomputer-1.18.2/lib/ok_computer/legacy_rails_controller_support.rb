module OkComputer
  module LegacyRailsControllerSupport
    def self.included(base)
      # Support <callback>_action for Rails 3
      %w(before after around).each do |callback|
        unless base.respond_to?("#{callback}_action")
          base.singleton_class.send(:alias_method, "#{callback}_action", "#{callback}_filter")
        end
      end
    end

    # Support 'render plain' for Rails 3
    def render(options = {}, &block)
      options[:text] = options.delete(:plain) if options.include?(:plain)
      super
    end
  end
end
