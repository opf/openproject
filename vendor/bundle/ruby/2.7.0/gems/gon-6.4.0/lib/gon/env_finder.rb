class Gon
  module EnvFinder
    ENV_CONTROLLER_KEY = 'action_controller.instance'
    ENV_RESPONSE_KEY = 'action_controller.rescue.response'

    class << self

      def controller_env(options = {})
        options[:controller] ||
          (
            current_gon &&
            current_gon.env[ENV_CONTROLLER_KEY] ||
            current_gon.env[ENV_RESPONSE_KEY].
              instance_variable_get('@template').
              instance_variable_get('@controller')
          )
      end

      def template_path(options, extension)
        if options[:template]
          if right_extension?(extension, options[:template])
            options[:template]
          else
            [options[:template], extension].join('.')
          end
        else
          controller = controller_env(options).controller_path
          action = controller_env(options).action_name
          "app/views/#{controller}/#{action}.json.#{extension}"
        end
      end

      private

      def right_extension?(extension, template_path)
        File.extname(template_path) == ".#{extension}"
      end

      def current_gon
        RequestStore.store[:gon]
      end

    end

  end
end
