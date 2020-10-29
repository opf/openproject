class Gon
  module Jbuilder
    class << self

      def handler(args, global = false)
        options = parse_options_from args
        valid_options? options, global

        controller = Gon::EnvFinder.controller_env(options)
        controller_name = global ? '' : controller.controller_path

        parser = Gon::Jbuilder::Parser.new(
          template_path: Gon::EnvFinder.template_path(options, 'jbuilder'),
          controller: controller,
          controller_name: controller_name,
          locals: options[:locals]
        )
        data = parser.parse!

        [data, options]
      end

      private

      def valid_options?(options, global)
        if global && !options[:template]
          raise 'You should provide :template when use jbuilder with global variables'
        end
      end

      def parse_options_from(args)
        if old_api? args
          text =  "[DEPRECATION] view_path argument is now optional. "
          text << "If you need to specify it, "
          text << "please use gon.jbuilder(:template => 'path')"
          warn text

          args.extract_options!.merge(:template => args[0])
        elsif new_api? args
          args.first
        else
          {}
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
