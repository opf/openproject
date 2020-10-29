# frozen_string_literal: true

module MetaTags
  # Class represents a collection of meta tags. Basically a wrapper around
  # HashWithIndifferentAccess, with some additional helper methods.
  class MetaTagsCollection
    attr_reader :meta_tags

    # Initializes a new instance of MetaTagsCollection.
    #
    def initialize
      @meta_tags = HashWithIndifferentAccess.new
    end

    # Returns meta tag value by name.
    #
    # @param [String, Symbol] name meta tag name.
    # @return meta tag value.
    #
    def [](name)
      @meta_tags[name]
    end

    # Sets meta tag value by name.
    #
    # @param [String, Symbol] name meta tag name.
    # @param value meta tag value.
    # @return meta tag value.
    #
    def []=(name, value)
      @meta_tags[name] = value
    end

    # Recursively merges a Hash of meta tag attributes into current list.
    #
    # @param [Hash, #to_meta_tags] object Hash of meta tags (or object responding
    #   to #to_meta_tags and returning a hash) to merge into the current list.
    # @return [Hash] result of the merge.
    #
    def update(object = {})
      meta_tags = object.respond_to?(:to_meta_tags) ? object.to_meta_tags : object
      @meta_tags.deep_merge! normalize_open_graph(meta_tags)
    end

    # Temporary merges defaults with current meta tags list and yields the block.
    #
    # @param [Hash] defaults list of default meta tag attributes.
    # @return result of the block call.
    #
    def with_defaults(defaults = {})
      old_meta_tags = @meta_tags
      @meta_tags = normalize_open_graph(defaults).deep_merge!(@meta_tags)
      yield
    ensure
      @meta_tags = old_meta_tags
    end

    # Constructs the full title as if it would be rendered in title meta tag.
    #
    # @param [Hash] defaults list of default meta tag attributes.
    # @return [String] page title.
    #
    def full_title(defaults = {})
      with_defaults(defaults) { extract_full_title }
    end

    # Constructs the title without site title (for normalized parameters).
    #
    # @return [String] page title.
    #
    def page_title(defaults = {})
      old_site = @meta_tags[:site]
      @meta_tags[:site] = nil
      with_defaults(defaults) { extract_full_title }
    ensure
      @meta_tags[:site] = old_site
    end

    # Deletes and returns a meta tag value by name.
    #
    # @param [String, Symbol] name meta tag name.
    # @return [Object] meta tag value.
    #
    def extract(name)
      @meta_tags.delete(name)
    end

    # Deletes specified meta tags.
    #
    # @param [Array<String, Symbol>] names a list of meta tags to delete.
    #
    def delete(*names)
      names.each { |name| @meta_tags.delete(name) }
    end

    # Extracts full page title and deletes all related meta tags.
    #
    # @return [String] page title.
    #
    def extract_full_title
      site_title = extract(:site) || ''
      title      = extract_title || []
      separator  = extract_separator
      reverse    = extract(:reverse) == true

      TextNormalizer.normalize_title(site_title, title, separator, reverse)
    end

    # Extracts page title as an array of segments without site title and separators.
    #
    # @return [Array<String>] segments of page title.
    #
    def extract_title
      title = extract(:title).presence
      return unless title

      title = Array(title)
      return title.map(&:downcase) if extract(:lowercase) == true

      title
    end

    # Extracts title separator as a string.
    #
    # @return [String] page title separator.
    #
    def extract_separator
      if meta_tags[:separator] == false
        # Special case: if separator is hidden, do not display suffix/prefix
        prefix = separator = suffix = ''
      else
        prefix    = extract_separator_section(:prefix, ' ')
        separator = extract_separator_section(:separator, '|')
        suffix    = extract_separator_section(:suffix, ' ')
      end
      delete(:separator, :prefix, :suffix)

      TextNormalizer.safe_join([prefix, separator, suffix], '')
    end

    # Extracts noindex settings as a Hash mapping noindex tag name to value.
    #
    # @return [Hash<String,String>] noindex attributes.
    #
    def extract_robots
      result = Hash.new { |h, k| h[k] = [] }

      [
        # noindex has higher priority than index
        [:noindex, :index],
        # follow has higher priority than nofollow
        [:follow, :nofollow],
        :noarchive,
      ].each do |attributes|
        calculate_robots_attributes(result, attributes)
      end

      result.transform_values { |v| v.join(', ') }
    end

    protected

    # Converts input hash to HashWithIndifferentAccess and renames :open_graph to :og.
    #
    # @param [Hash] meta_tags list of meta tags.
    # @return [HashWithIndifferentAccess] normalized meta tags list.
    #
    def normalize_open_graph(meta_tags)
      meta_tags = meta_tags.kind_of?(HashWithIndifferentAccess) ? meta_tags.dup : meta_tags.with_indifferent_access
      meta_tags[:og] = meta_tags.delete(:open_graph) if meta_tags.key?(:open_graph)
      meta_tags
    end

    # Extracts separator segment without deleting it from meta tags list.
    # If the value is false, empty string will be returned.
    #
    # @param [Symbol, String] name separator segment name.
    # @param [String] default default value.
    # @return [String] separator segment value.
    #
    def extract_separator_section(name, default)
      meta_tags[name] == false ? '' : (meta_tags[name] || default)
    end

    # Extracts robots attribute (noindex, nofollow, etc) name and value.
    #
    # @param [String, Symbol] name noindex attribute name.
    # @return [Array<String>] pair of noindex attribute name and value.
    #
    def extract_robots_attribute(name)
      noindex       = extract(name)
      noindex_name  = noindex.kind_of?(String) || noindex.kind_of?(Array) ? noindex : 'robots'
      noindex_value = noindex ? name.to_s : nil

      [ noindex_name, noindex_value ]
    end

    def calculate_robots_attributes(result, attributes)
      processed = Set.new
      Array(attributes).each do |attribute|
        names, value = extract_robots_attribute(attribute)
        next unless value

        Array(names).each do |name|
          apply_robots_value(result, name, value, processed)
        end
      end
    end

    def apply_robots_value(result, name, value, processed)
      name = name.to_s
      return if processed.include?(name)

      result[name] << value
      processed << name
    end
  end
end
