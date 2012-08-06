module ActionView
  class Resolver
    def find_all(name, prefix=nil, partial=false, details={}, key=nil, locals=[])
      cached(key, [name, prefix, partial], details, locals) do
        if details[:formats] & [:xml, :json]
          details = details.dup
          details[:formats] = details[:formats].dup + [:api]
        end
        find_templates(name, prefix, partial, details)
      end
    end
  end
end

module ActionController
  module MimeResponds
    class Collector
      def api(&block)
        any(:xml, :json, &block)
      end
    end
  end
end
