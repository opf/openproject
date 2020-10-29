# frozen_string_literal: true

module MetaTags
  # MetaTags configuration.
  class Configuration
    # How many characters to truncate title to.
    attr_accessor :title_limit

    # Truncate site_title instead of title.
    attr_accessor :truncate_site_title_first

    # How many characters to truncate description to.
    attr_accessor :description_limit

    # How many characters to truncate keywords to.
    attr_accessor :keywords_limit

    # Keywords separator - a string to join keywords with.
    attr_accessor :keywords_separator

    # Should keywords forced into lowercase?
    attr_accessor :keywords_lowercase

    # Switches between open (<meta ... >) and closed (<meta ... />) meta tags.
    # Default is true, which means "open".
    attr_accessor :open_meta_tags

    # When true, the output will not include new line characters between meta tags.
    # Default is false.
    attr_accessor :minify_output

    # Custom meta tags that should use `property` attribute instead of `name`
    # - an array of strings or symbols representing their names or name-prefixes.
    attr_reader :property_tags

    # Initializes a new instance of Configuration class.
    def initialize
      reset_defaults!
    end

    def default_property_tags
      [
        # App Link metadata https://developers.facebook.com/docs/applinks/metadata-reference
        'al',
        # Open Graph Markup https://developers.facebook.com/docs/sharing/webmasters#markup
        'fb',
        'og',
        # Facebook OpenGraph Object Types https://developers.facebook.com/docs/reference/opengraph
        # Note that these tags are used in a regex, so including e.g. 'restaurant' will affect
        # 'restaurant:category', 'restaurant:price_rating', and anything else under that namespace.
        'article',
        'book',
        'books',
        'business',
        'fitness',
        'game',
        'music',
        'place',
        'product',
        'profile',
        'restaurant',
        'video',
      ].freeze
    end

    def open_meta_tags?
      !!open_meta_tags
    end

    def reset_defaults!
      @title_limit = 70
      @truncate_site_title_first = false
      @description_limit = 300
      @keywords_limit = 255
      @keywords_separator = ', '
      @keywords_lowercase = true
      @property_tags = default_property_tags.dup
      @open_meta_tags = true
      @minify_output = false
    end
  end
end
