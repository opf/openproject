require 'sequel'
require 'sequel/extensions/pagination'
require 'will_paginate/collection'

module WillPaginate
  # Sequel already supports pagination; we only need to make the
  # resulting dataset look a bit more like WillPaginate::Collection
  module SequelMethods
    include WillPaginate::CollectionMethods

    def total_pages
      page_count
    end

    def per_page
      page_size
    end

    def size
      current_page_record_count
    end
    alias length size

    def total_entries
      pagination_record_count
    end

    def out_of_bounds?
      current_page > total_pages
    end

    # Current offset of the paginated collection
    def offset
      (current_page - 1) * per_page
    end
  end

  Sequel::Dataset::Pagination.send(:include, SequelMethods)
end
