class Gon
  module Jbuilder
    class Parser
      include ::ActionView::Helpers

      attr_accessor :template_location, :controller, :_controller_name, :locals

      def initialize(parse_params)
        @template_location = parse_params[:template_path]
        @controller        = parse_params[:controller]
        @_controller_name  = parse_params[:controller_name]
        @locals            = parse_params[:locals] || {}
      end

      def parse!
        assign_controller_variables controller
        eval_controller_helpers controller
        eval_controller_url_helpers controller
        locals['__controller'] = controller
        wrap_locals_in_methods locals

        partials = find_partials(File.readlines(template_location))
        source = partials.join('')

        parse_source source, controller
      end

      def assign_controller_variables(controller)
        controller.instance_variables.each do |name|
          self.instance_variable_set \
            name,
            controller.instance_variable_get(name)
        end
      end

      def eval_controller_helpers(controller)
        controller._helper_methods.each do |meth|
          self.class.class_eval <<-ruby_eval, __FILE__, __LINE__ + 1
              def #{meth}(*args, &blk)                               # def current_user(*args, &blk)
                __controller.send(%(#{meth}), *args, &blk)             #   controller.send(:current_user, *args, &blk)
              end                                                    # end
            ruby_eval
        end
      end

      def eval_controller_url_helpers(controller)
        if defined?(Rails) && Rails.respond_to?(:application)
          Rails.application.routes.url_helpers.instance_methods.each do |meth|
            self.class.class_eval <<-ruby_eval, __FILE__, __LINE__ + 1
              def #{meth}(*args, &blk)                                         # def user_path(*args, &blk)
                __controller.send(%(#{meth}), *args, &blk)                     #   controller.send(:user_path, *args, &blk)
              end                                                              # end
            ruby_eval
          end
        end
      end

      def wrap_locals_in_methods(locals)
        locals.each do |name, value|
          self.class.class_eval do
            define_method "#{name}" do
              return value
            end
          end
        end
      end

      def parse_source(source, controller)
        output = ::JbuilderTemplate.encode(controller) do |json|
          eval source
        end
        JSON.parse(output)
      end

      def parse_partial(partial_line)
        path = partial_line.match(/['"]([^'"]*)['"]/)[1]
        path = parse_path path
        options_hash = partial_line.match(/,(.*)/)[1]

        set_options_from_hash(options_hash) if options_hash.present?

        find_partials File.readlines(path)
      end

      def set_options_from_hash(options_hash)
        options = eval "{#{options_hash}}"
        options.each do |name, val|
          self.instance_variable_set("@#{name.to_s}", val)
          eval "def #{name}; self.instance_variable_get('@' + '#{name.to_s}'); end"
        end
      end

      def parse_path(path)
        return path if File.exists?(path)
        if (splitted = path.split('/')).blank?
            raise 'Something wrong with partial path in your jbuilder templates'
        elsif splitted.size == 1
            splitted.shift(@_controller_name)
        end
        construct_path(splitted)
      end

      def construct_path(args)
        last_arg = args.pop
        tmp_path = 'app/views/' + args.join('/')
        path = path_with_ext(tmp_path + "/_#{last_arg}")
        path || path_with_ext(tmp_path + "/#{last_arg}")
      end

      def path_with_ext(path)
        return path if File.exists?(path)
        return "#{path}.jbuilder" if File.exists?("#{path}.jbuilder")
        return "#{path}.json.jbuilder" if File.exists?("#{path}.json.jbuilder")
      end

      def find_partials(lines = [])
        lines.map do |line|
          if line =~ /partial!/
            parse_partial line
          else
            line
          end
        end.flatten
      end

    end
  end
end
