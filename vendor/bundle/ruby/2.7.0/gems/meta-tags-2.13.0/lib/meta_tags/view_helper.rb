# frozen_string_literal: true

module MetaTags
  # Contains methods to use in views and helpers.
  #
  module ViewHelper
    # Get meta tags for the page.
    def meta_tags
      @meta_tags ||= MetaTagsCollection.new
    end

    # Set meta tags for the page.
    #
    # Method could be used several times, and all options passed will
    # be merged. If you will set the same property several times, last one
    # will take precedence.
    #
    # Usually you will not call this method directly. Use {#title}, {#keywords},
    # {#description} for your daily tasks.
    #
    # @param [Hash] meta_tags list of meta tags. See {#display_meta_tags}
    #   for allowed options.
    #
    # @example
    #   set_meta_tags title: 'Login Page', description: 'Here you can login'
    #   set_meta_tags keywords: 'authorization, login'
    #
    # @see #display_meta_tags
    #
    def set_meta_tags(meta_tags = {}) # rubocop:disable Naming/AccessorMethodName
      self.meta_tags.update(meta_tags)
    end

    # Set the page title and return it back.
    #
    # This method is best suited for use in helpers. It sets the page title
    # and returns it (or +headline+ if specified).
    #
    # @param [nil, String, Array] title page title. When passed as an
    #   +Array+, parts will be joined using configured separator value
    #   (see {#display_meta_tags}). When nil, current title will be returned.
    # @param [String] headline the value to return from method. Useful
    #   for using this method in views to set both page title
    #   and the content of heading tag.
    # @return [String] returns +title+ value or +headline+ if passed.
    #
    # @example Set HTML title to "Please login", return "Please login"
    #   title 'Login Page'
    # @example Set HTML title to "Login Page", return "Please login"
    #   title 'Login Page', 'Please login'
    # @example Set title as array of strings
    #   title title: ['part1', 'part2'] # => "part1 | part2"
    # @example Get current title
    #   title
    #
    # @see #display_meta_tags
    #
    def title(title = nil, headline = '')
      set_meta_tags(title: title) unless title.nil?
      headline.presence || meta_tags[:title]
    end

    # Set the page keywords.
    #
    # @param [String, Array] keywords meta keywords to render in HEAD
    #   section of the HTML document.
    # @return [String, Array] passed value.
    #
    # @example
    #   keywords 'keyword1, keyword2'
    #   keywords %w(keyword1 keyword2)
    #
    # @see #display_meta_tags
    #
    def keywords(keywords)
      set_meta_tags(keywords: keywords)
      keywords
    end

    # Set the page description.
    #
    # @param [String] description page description to be set in HEAD section of
    #   the HTML document. Please note, any HTML tags will be stripped
    #   from output string, and string will be truncated to 200
    #   characters.
    # @return [String] passed value.
    #
    # @example
    #   description 'This is login page'
    #
    # @see #display_meta_tags
    #
    def description(description)
      set_meta_tags(description: description)
      description
    end

    # Set the noindex meta tag
    #
    # @param [Boolean, String] noindex a noindex value.
    # @return [Boolean, String] passed value.
    #
    # @example
    #   noindex true
    #   noindex 'googlebot'
    #
    # @see #display_meta_tags
    #
    def noindex(noindex = true)
      set_meta_tags(noindex: noindex)
      noindex
    end

    # Set the nofollow meta tag
    #
    # @param [Boolean, String] nofollow a nofollow value.
    # @return [Boolean, String] passed value.
    #
    # @example
    #   nofollow true
    #   nofollow 'googlebot'
    #
    # @see #display_meta_tags
    #
    def nofollow(nofollow = true)
      set_meta_tags(nofollow: nofollow)
      nofollow
    end

    # Set the refresh meta tag
    #
    # @param [Integer, String] refresh a refresh value.
    # @return [Integer, String] passed value.
    #
    # @example
    #   refresh 5
    #   refresh "5;url=http://www.example.com/"
    #
    # @see #display_meta_tags
    #
    def refresh(refresh)
      set_meta_tags(refresh: refresh)
      refresh
    end

    # Set default meta tag values and display meta tags. This method
    # should be used in layout file.
    #
    # @param [Hash] defaults default meta tag values.
    # @option default [String] :site (nil) site title;
    # @option default [String] :title ("") page title;
    # @option default [String] :description (nil) page description;
    # @option default [String] :keywords (nil) page keywords;
    # @option default [String, Boolean] :prefix (" ") text between site name and separator;
    #                                   when +false+, no prefix will be rendered;
    # @option default [String] :separator ("|") text used to separate website name from page title;
    # @option default [String, Boolean] :suffix (" ") text between separator and page title;
    #                                   when +false+, no suffix will be rendered;
    # @option default [Boolean] :lowercase (false) when true, the page title will be lowercase;
    # @option default [Boolean] :reverse (false) when true, the page and site names will be reversed;
    # @option default [Boolean, String] :noindex (false) add noindex meta tag; when true, 'robots' will be used,
    #                                   otherwise the string will be used;
    # @option default [Boolean, String] :nofollow (false) add nofollow meta tag; when true, 'robots' will be used,
    #                                   otherwise the string will be used;
    # @option default [String] :canonical (nil) add canonical link tag.
    # @option default [Hash] :alternate ({}) add alternate link tag.
    # @option default [String] :prev (nil) add prev link tag;
    # @option default [String] :next (nil) add next link tag.
    # @option default [String, Integer] :refresh (nil) meta refresh tag;
    # @option default [Hash] :open_graph ({}) add Open Graph meta tags.
    # @option default [Hash] :open_search ({}) add Open Search link tag.
    # @return [String] HTML meta tags to render in HEAD section of the
    #   HTML document.
    #
    # @example
    #   <head>
    #     <%= display_meta_tags site: 'My website' %>
    #   </head>
    #
    def display_meta_tags(defaults = {})
      meta_tags.with_defaults(defaults) { Renderer.new(meta_tags).render(self) }
    end

    # Returns full page title as a string without surrounding <title> tag.
    #
    # The only case when you may need this helper is when you use pjax. This means
    # that your layout file (with display_meta_tags helper) will not be rendered,
    # so you have to pass default arguments like site title in here. You probably
    # want to define helper with default options to minimize code duplication.
    #
    # @param [Hash] defaults list of meta tags.
    # @option default [String] :site (nil) site title;
    # @option default [String] :title ("") page title;
    # @option default [String, Boolean] :prefix (" ") text between site name and separator; when +false+,
    #                                   no prefix will be rendered;
    # @option default [String] :separator ("|") text used to separate website name from page title;
    # @option default [String, Boolean] :suffix (" ") text between separator and page title; when +false+,
    #                                   no suffix will be rendered;
    # @option default [Boolean] :lowercase (false) when true, the page name will be lowercase;
    # @option default [Boolean] :reverse (false) when true, the page and site names will be reversed;
    #
    # @example
    #   <div data-page-container="true" title="<%= display_title title: 'My Page', site: 'PJAX Site' %>">
    #
    def display_title(defaults = {})
      @meta_tags.full_title(defaults)
    end
  end
end
