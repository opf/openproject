require 'will_paginate/core_ext'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'

module WillPaginate
  module Merb
    include ViewHelpers

    def will_paginate(collection, options = {}) #:nodoc:
      options = options.merge(:renderer => LinkRenderer) unless options[:renderer]
      super(collection, options)
    end

    class LinkRenderer < ViewHelpers::LinkRenderer
      protected

      def url(page)
        params = @template.request.params.except(:action, :controller).merge(param_name => page)
        @template.url(:this, params)
      end
    end

    ::Merb::AbstractController.send(:include, self)
  end
end

