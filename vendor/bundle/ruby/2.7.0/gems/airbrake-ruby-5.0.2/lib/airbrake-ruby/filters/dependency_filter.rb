module Airbrake
  module Filters
    # Attaches loaded dependencies to the notice object.
    #
    # @api private
    # @since v2.10.0
    class DependencyFilter
      def initialize
        @weight = 117
      end

      # @macro call_filter
      def call(notice)
        deps = {}
        Gem.loaded_specs.map.with_object(deps) do |(name, spec), h|
          h[name] = "#{spec.version}#{git_version(spec)}"
        end

        notice[:context][:versions] = {} unless notice[:context].key?(:versions)
        notice[:context][:versions][:dependencies] = deps
      end

      private

      def git_version(spec)
        return unless spec.respond_to?(:git_version) || spec.git_version

        spec.git_version.to_s
      end
    end
  end
end
