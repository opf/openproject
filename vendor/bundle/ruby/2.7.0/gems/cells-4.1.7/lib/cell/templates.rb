module Cell
  # Gets cached in production.
  class Templates
    # prefixes could be instance variable as they will never change.
    def [](prefixes, view, options)
      find_template(prefixes, view, options)
    end

  private

    def cache
      @cache ||= Cache.new
    end

    def find_template(prefixes, view, options) # options is not considered in cache key.
      cache.fetch(prefixes, view) do |prefix|
        # this block is run once per cell class per process, for each prefix/view tuple.
        create(prefix, view, options)
      end
    end

    def create(prefix, view, options)
      # puts "...checking #{prefix}/#{view}"
      return unless File.exist?("#{prefix}/#{view}") # DISCUSS: can we use Tilt.new here?

      template_class = options.delete(:template_class)
      template_class.new("#{prefix}/#{view}", options) # Tilt.new()
    end

    # {["comment/row/views", comment/views"]["show.haml"] => "Tpl:comment/view/show.haml"}
    class Cache
      def initialize
        @store = {}
      end

      # Iterates prefixes and yields block. Returns and caches when block returned template.
      # Note that it caches per prefixes set as this will most probably never change.
      def fetch(prefixes, view)
        template = get(prefixes, view) and return template # cache hit.

        prefixes.find do |prefix|
          template = yield(prefix) and return store(prefixes, view, template)
        end
      end

    private
      # ["comment/views"] => "show.haml"
      def get(prefixes, view)
        @store[prefixes] ||= {}
        @store[prefixes][view]
      end

      def store(prefix, view, template)
        @store[prefix][view] = template # the nested hash is always present here.
      end
    end
  end
end
