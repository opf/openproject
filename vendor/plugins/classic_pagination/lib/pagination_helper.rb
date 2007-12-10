module ActionView
  module Helpers
    # Provides methods for linking to ActionController::Pagination objects using a simple generator API.  You can optionally
    # also build your links manually using ActionView::Helpers::AssetHelper#link_to like so:
    #
    # <%= link_to "Previous page", { :page => paginator.current.previous } if paginator.current.previous %>
    # <%= link_to "Next page", { :page => paginator.current.next } if paginator.current.next %>
    module PaginationHelper
      unless const_defined?(:DEFAULT_OPTIONS)
        DEFAULT_OPTIONS = {
          :name => :page,
          :window_size => 2,
          :always_show_anchors => true,
          :link_to_current_page => false,
          :params => {}
        }
      end

      # Creates a basic HTML link bar for the given +paginator+.  Links will be created
      # for the next and/or previous page and for a number of other pages around the current
      # pages position. The +html_options+ hash is passed to +link_to+ when the links are created.
      #
      # ==== Options
      # <tt>:name</tt>::                 the routing name for this paginator
      #                                  (defaults to +page+)
      # <tt>:prefix</tt>::               prefix for pagination links
      #                                  (i.e. Older Pages: 1 2 3 4)
      # <tt>:suffix</tt>::               suffix for pagination links
      #                                  (i.e. 1 2 3 4 <- Older Pages)
      # <tt>:window_size</tt>::          the number of pages to show around 
      #                                  the current page (defaults to <tt>2</tt>)
      # <tt>:always_show_anchors</tt>::  whether or not the first and last
      #                                  pages should always be shown
      #                                  (defaults to +true+)
      # <tt>:link_to_current_page</tt>:: whether or not the current page
      #                                  should be linked to (defaults to
      #                                  +false+)
      # <tt>:params</tt>::               any additional routing parameters
      #                                  for page URLs
      #
      # ==== Examples
      #  # We'll assume we have a paginator setup in @person_pages...
      #
      #  pagination_links(@person_pages)
      #  # => 1 <a href="/?page=2/">2</a> <a href="/?page=3/">3</a>  ... <a href="/?page=10/">10</a>
      #
      #  pagination_links(@person_pages, :link_to_current_page => true)
      #  # => <a href="/?page=1/">1</a> <a href="/?page=2/">2</a> <a href="/?page=3/">3</a>  ... <a href="/?page=10/">10</a>
      #
      #  pagination_links(@person_pages, :always_show_anchors => false)
      #  # => 1 <a href="/?page=2/">2</a> <a href="/?page=3/">3</a> 
      #
      #  pagination_links(@person_pages, :window_size => 1)
      #  # => 1 <a href="/?page=2/">2</a>  ... <a href="/?page=10/">10</a>
      #
      #  pagination_links(@person_pages, :params => { :viewer => "flash" })
      #  # => 1 <a href="/?page=2&amp;viewer=flash/">2</a> <a href="/?page=3&amp;viewer=flash/">3</a>  ... 
      #  #    <a href="/?page=10&amp;viewer=flash/">10</a>
      def pagination_links(paginator, options={}, html_options={})
        name = options[:name] || DEFAULT_OPTIONS[:name]
        params = (options[:params] || DEFAULT_OPTIONS[:params]).clone
        
        prefix = options[:prefix] || ''
        suffix = options[:suffix] || ''

        pagination_links_each(paginator, options, prefix, suffix) do |n|
          params[name] = n
          link_to(n.to_s, params, html_options)
        end
      end

      # Iterate through the pages of a given +paginator+, invoking a
      # block for each page number that needs to be rendered as a link.
      # 
      # ==== Options
      # <tt>:window_size</tt>::          the number of pages to show around 
      #                                  the current page (defaults to +2+)
      # <tt>:always_show_anchors</tt>::  whether or not the first and last
      #                                  pages should always be shown
      #                                  (defaults to +true+)
      # <tt>:link_to_current_page</tt>:: whether or not the current page
      #                                  should be linked to (defaults to
      #                                  +false+)
      #
      # ==== Example
      #  # Turn paginated links into an Ajax call
      #  pagination_links_each(paginator, page_options) do |link|
      #    options = { :url => {:action => 'list'}, :update => 'results' }
      #    html_options = { :href => url_for(:action => 'list') }
      #
      #    link_to_remote(link.to_s, options, html_options)
      #  end
      def pagination_links_each(paginator, options, prefix = nil, suffix = nil)
        options = DEFAULT_OPTIONS.merge(options)
        link_to_current_page = options[:link_to_current_page]
        always_show_anchors = options[:always_show_anchors]

        current_page = paginator.current_page
        window_pages = current_page.window(options[:window_size]).pages
        return if window_pages.length <= 1 unless link_to_current_page
        
        first, last = paginator.first, paginator.last
        
        html = ''

        html << prefix if prefix

        if always_show_anchors and not (wp_first = window_pages[0]).first?
          html << yield(first.number)
          html << ' ... ' if wp_first.number - first.number > 1
          html << ' '
        end
          
        window_pages.each do |page|
          if current_page == page && !link_to_current_page
            html << page.number.to_s
          else
            html << yield(page.number)
          end
          html << ' '
        end
        
        if always_show_anchors and not (wp_last = window_pages[-1]).last? 
          html << ' ... ' if last.number - wp_last.number > 1
          html << yield(last.number)
        end

        html << suffix if suffix

        html
      end
      
    end # PaginationHelper
  end # Helpers
end # ActionView
