require 'will_paginate/per_page'
require 'will_paginate/page_number'

module WillPaginate
  # Any will_paginate-compatible collection should have these methods:
  #
  #   current_page, per_page, offset, total_entries, total_pages
  #
  # It can also define some of these optional methods:
  #
  #   out_of_bounds?, previous_page, next_page
  #
  # This module provides few of these methods.
  module CollectionMethods
    def total_pages
      total_entries.zero? ? 1 : (total_entries / per_page.to_f).ceil
    end

    # current_page - 1 or nil if there is no previous page
    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end

    # current_page + 1 or nil if there is no next page
    def next_page
      current_page < total_pages ? (current_page + 1) : nil
    end

    # Helper method that is true when someone tries to fetch a page with a
    # larger number than the last page. Can be used in combination with flashes
    # and redirecting.
    def out_of_bounds?
      current_page > total_pages
    end
  end

  # = The key to pagination
  # Arrays returned from paginating finds are, in fact, instances of this little
  # class. You may think of WillPaginate::Collection as an ordinary array with
  # some extra properties. Those properties are used by view helpers to generate
  # correct page links.
  #
  # WillPaginate::Collection also assists in rolling out your own pagination
  # solutions: see +create+.
  # 
  # If you are writing a library that provides a collection which you would like
  # to conform to this API, you don't have to copy these methods over; simply
  # make your plugin/gem dependant on this library and do:
  #
  #   require 'will_paginate/collection'
  #   # WillPaginate::Collection is now available for use
  class Collection < Array
    include CollectionMethods

    attr_reader :current_page, :per_page, :total_entries

    # Arguments to the constructor are the current page number, per-page limit
    # and the total number of entries. The last argument is optional because it
    # is best to do lazy counting; in other words, count *conditionally* after
    # populating the collection using the +replace+ method.
    def initialize(page, per_page = WillPaginate.per_page, total = nil)
      @current_page = WillPaginate::PageNumber(page)
      @per_page = per_page.to_i
      self.total_entries = total if total
    end

    # Just like +new+, but yields the object after instantiation and returns it
    # afterwards. This is very useful for manual pagination:
    #
    #   @entries = WillPaginate::Collection.create(1, 10) do |pager|
    #     result = Post.find(:all, :limit => pager.per_page, :offset => pager.offset)
    #     # inject the result array into the paginated collection:
    #     pager.replace(result)
    #
    #     unless pager.total_entries
    #       # the pager didn't manage to guess the total count, do it manually
    #       pager.total_entries = Post.count
    #     end
    #   end
    #
    # The possibilities with this are endless. For another example, here is how
    # WillPaginate used to define pagination for Array instances:
    #
    #   Array.class_eval do
    #     def paginate(page = 1, per_page = 15)
    #       WillPaginate::Collection.create(page, per_page, size) do |pager|
    #         pager.replace self[pager.offset, pager.per_page].to_a
    #       end
    #     end
    #   end
    #
    # The Array#paginate API has since then changed, but this still serves as a
    # fine example of WillPaginate::Collection usage.
    def self.create(page, per_page, total = nil)
      pager = new(page, per_page, total)
      yield pager
      pager
    end

    # Current offset of the paginated collection. If we're on the first page,
    # it is always 0. If we're on the 2nd page and there are 30 entries per page,
    # the offset is 30. This property is useful if you want to render ordinals
    # side by side with records in the view: simply start with offset + 1.
    def offset
      current_page.to_offset(per_page).to_i
    end

    def total_entries=(number)
      @total_entries = number.to_i
    end

    # This is a magic wrapper for the original Array#replace method. It serves
    # for populating the paginated collection after initialization.
    #
    # Why magic? Because it tries to guess the total number of entries judging
    # by the size of given array. If it is shorter than +per_page+ limit, then we
    # know we're on the last page. This trick is very useful for avoiding
    # unnecessary hits to the database to do the counting after we fetched the
    # data for the current page.
    #
    # However, after using +replace+ you should always test the value of
    # +total_entries+ and set it to a proper value if it's +nil+. See the example
    # in +create+.
    def replace(array)
      result = super
      
      # The collection is shorter then page limit? Rejoice, because
      # then we know that we are on the last page!
      if total_entries.nil? and length < per_page and (current_page == 1 or length > 0)
        self.total_entries = offset + length
      end

      result
    end
  end
end
