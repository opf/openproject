require 'hanami/view'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'

module WillPaginate
  module Hanami
    module Helpers
      include ViewHelpers

      def will_paginate(collection, options = {}) #:nodoc:
        options = options.merge(:renderer => LinkRenderer) unless options[:renderer]
        str = super(collection, options)
        str && raw(str)
      end
    end

    class LinkRenderer < ViewHelpers::LinkRenderer
      protected

      def url(page)
        str = File.join(request_env['SCRIPT_NAME'].to_s, request_env['PATH_INFO'])
        params = request_env['rack.request.query_hash'].merge(param_name.to_s => page.to_s)
        params.update @options[:params] if @options[:params]
        str << '?' << build_query(params)
      end

      def request_env
        @template.params.env
      end

      def build_query(params)
        Rack::Utils.build_nested_query params
      end
    end

    def self.included(base)
      base.include Helpers
    end

  end
end
