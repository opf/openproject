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

    register_tag('child_pages', ChildPages, :html => true)
    register_tag('hello_world', HelloWorld)
    register_tag('include', Include, :html => true)
    register_tag('tag_list', TagList, :html => true)
    register_tag('variable_list', VariableList, :html => true)
  end
end

