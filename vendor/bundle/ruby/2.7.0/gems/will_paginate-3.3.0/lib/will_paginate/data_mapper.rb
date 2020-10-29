require 'dm-core'
require 'dm-aggregates'
require 'will_paginate/per_page'
require 'will_paginate/page_number'
require 'will_paginate/collection'

module WillPaginate
  module DataMapper
    module Pagination
      def page(num)
        pagenum = ::WillPaginate::PageNumber(num.nil? ? 1 : num)
        per_page = query.limit || self.per_page
        options = {:offset => pagenum.to_offset(per_page).to_i}
        options[:limit] = per_page unless query.limit
        col = new_collection(query.merge(options))
        col.current_page = pagenum
        col
      end

      def paginate(options)
        options  = options.dup
        pagenum  = options.fetch(:page) { raise ArgumentError, ":page parameter required" }
        per_page = options.delete(:per_page) || self.per_page
        total    = options.delete(:total_entries)

        options.delete(:page)
        options[:limit] = per_page.to_i


        col = all(options).page(pagenum)
        col.total_entries = total.to_i unless total.nil? || (total.kind_of?(String) && total.strip.empty?)
        col
      end
    end

    module CollectionMethods
      include WillPaginate::CollectionMethods

      attr_accessor :current_page
      attr_writer :total_entries

      def paginated?
        !current_page.nil?
      end

      def per_page
        query.limit || model.per_page
      end

      def offset
        query.offset
      end

      def total_entries
        @total_entries ||= begin
          if loaded? and @array.size < per_page and (current_page == 1 or @array.size > 0)
            offset + @array.size
          else
            # :reload prevents Collection.filter from being run, which
            # would cause a stack overflow
            clean_query = query.merge(:reload => true)
            # seems like the only way
            clean_query.instance_variable_set('@limit', nil)
            clean_query.instance_variable_set('@offset', 0)
            new_collection(clean_query).count
          end
        end
      end

      def to_a
        if paginated?
          ::WillPaginate::Collection.create(current_page, per_page) do |col|
            col.replace super
            col.total_entries ||= total_entries
          end
        else
          super
        end
      end

      private

      def new_collection(query, resources = nil)
        col = super
        col.current_page = self.current_page
        col
      end

      def initialize_copy(original)
        super
        @total_entries = nil
      end
    end

    ::DataMapper::Model.append_extensions PerPage
    ::DataMapper::Model.append_extensions Pagination
    ::DataMapper::Collection.send(:include, Pagination)
    ::DataMapper::Collection.send(:include, CollectionMethods)
  end
end
