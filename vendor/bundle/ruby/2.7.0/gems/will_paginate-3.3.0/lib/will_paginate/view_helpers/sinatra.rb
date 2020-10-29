require 'sinatra/base'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'

module WillPaginate
  module Sinatra
    module Helpers
      include ViewHelpers

      def will_paginate(collection, options = {}) #:nodoc:
        options = options.merge(:renderer => LinkRenderer) unless options[:renderer]
        super(collection, options)
      end
    end

    class LinkRenderer < ViewHelpers::LinkRenderer
      protected

      def url(page)
        str = File.join(request.script_name.to_s, request.path_info)
        params = request.GET.merge(param_name.to_s => page.to_s)
        params.update @options[:params] if @options[:params]
        str << '?' << build_query(params)
      end

      def request
        @template.request
      end

      def build_query(params)
        Rack::Utils.build_nested_query params
      end
    end

    def self.registered(app)
      app.helpers Helpers
    end

    ::Sinatra.register self
  end
end
