module ChiliProject::Liquid
  module Tags
    class TagError < StandardError; end

    def self.register_tag(name, klass, options={})
      if options[:html]
        html_class = Class.new do
          def render(context)
            result = @tag.render(context)
            context.html_result(result)
          end

          def method_missing(*args, &block)
            @tag.send(*args, &block)
          end
        end
        html_class.send :define_method, :initialize do |*args|
          @tag = klass.new(*args)
        end
        ::Liquid::Template.register_tag(name, html_class)
      else
        ::Liquid::Template.register_tag(name, klass)
      end
    end

    # TODO: reimplement old macros as tags and register them here
    # child_pages
    # hello_world
    # include
    # macro_list
  end
end
