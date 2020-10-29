require 'mongoid'
require 'will_paginate/collection'

module WillPaginate
  module Mongoid
    module CriteriaMethods
      def paginate(options = {})
        extend CollectionMethods
        @current_page = WillPaginate::PageNumber(options[:page] || @current_page || 1)
        @page_multiplier = current_page - 1
        @total_entries = options.delete(:total_entries)

        pp = (options[:per_page] || per_page || WillPaginate.per_page).to_i
        limit(pp).skip(@page_multiplier * pp)
      end

      def per_page(value = :non_given)
        if value == :non_given
          options[:limit] == 0 ? nil : options[:limit] # in new Mongoid versions a nil limit is saved as 0
        else
          limit(value)
        end
      end

      def page(page)
        paginate(:page => page)
      end
    end

    module CollectionMethods
      attr_reader :current_page

      def total_entries
        @total_entries ||= count
      end

      def total_pages
        (total_entries / per_page.to_f).ceil
      end

      def offset
        @page_multiplier * per_page
      end
    end

    ::Mongoid::Criteria.send(:include, CriteriaMethods)
  end
end
