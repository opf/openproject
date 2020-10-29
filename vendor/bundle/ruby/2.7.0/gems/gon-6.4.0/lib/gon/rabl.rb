require 'action_view'

begin
  require 'rabl' # use rabl gem if it's available
rescue LoadError
end
begin
  require 'rabl-rails' # use rabl-rails gem if it's available
rescue LoadError
end

class Gon
  module Rabl
    class << self

      def handler(args, global = false)
        options = parse_options_from args, global
        if global && !options[:template]
          raise 'You should provide :template when use rabl with global variables'
        end

        data = parse_rabl \
          Gon::EnvFinder.template_path(options, 'rabl'),
          Gon::EnvFinder.controller_env(options),
          options[:locals]

        [data, options]
      end

      private

      def parse_rabl(rabl_path, controller, locals)
        if defined? ::Rabl
          parse_with_rabl rabl_path, controller, locals
        elsif defined? ::RablRails
          parse_with_rabl_rails rabl_path, controller, locals
        else
          raise 'rabl or rabl-rails must be required in order to use gon.rabl'
        end
      end

      def parse_with_rabl(rabl_path, controller, locals)
        locals ||= {}
        source = File.read(rabl_path)
        include_helpers
        rabl_engine = ::Rabl::Engine.new(source, :format => 'json', :template => rabl_path)
        output = rabl_engine.render(controller, locals)
        JSON.parse(output)
      end

      def parse_with_rabl_rails(rabl_path, controller, locals)
        locals ||= {}
        source = File.read(rabl_path)
        original_formats = controller.formats
        controller.formats = [:json]
        view_context = controller.send(:view_context)
        locals.each { |k, v| view_context.assigns[k.to_s] = v }
        output = RablRails::Library.instance.get_rendered_template(source, view_context)
        controller.formats = original_formats
        JSON.parse(output)
      end

      def parse_options_from(args, global)
        if old_api? args
          unless global
            text =  "[DEPRECATION] view_path argument is now optional. "
            text << "If you need to specify it, "
            text << "please use gon.rabl(:template => 'path')"
            warn text
          end

          args.extract_options!.merge(:template => args[0])
        elsif new_api? args
          args.first
        else
          {}
        end
      end

      def include_helpers
        unless ::Rabl::Engine.include? ::ActionView::Helpers
          ::Rabl::Engine.send(:include, ::ActionView::Helpers)
        end
      end

      def old_api?(args)
        args.first.is_a? String
      end

      def new_api?(args)
        args.first.is_a? Hash
      end

    end
  end
end
