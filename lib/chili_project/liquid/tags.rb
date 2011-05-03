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
    register_tag('hello_world', HelloWorld)
    # include
    register_tag('tag_list', TagList, :html => true)
    register_tag('variable_list', VariableList, :html => true)
  end
end

# FIXME: remove the deprecated syntax for 4.0, provide a way to migrate
# existing pages to the new syntax.
ChiliProject::Liquid::Legacy.add('hello_world', :tag)
