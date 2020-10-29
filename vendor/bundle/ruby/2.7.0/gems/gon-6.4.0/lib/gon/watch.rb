class Gon
  class Watch < Gon
    class << self

      JS_FUNCTION = File.read(File.expand_path('../../../js/watch.js', __FILE__))

      def render
        JS_FUNCTION + "window.gon.watchedVariables=#{Gon::JsonDumper.dump all_variables};"
      end

      def render_amd
        JS_FUNCTION + "gon.watchedVariables=#{Gon::JsonDumper.dump all_variables};"
      end

      def all_variables
        @watch_variables || {}
      end

      def clear
        @watch_variables = {}
      end

      private

      def set_variable(name, value)
        if return_variable?(name)
          return_variable value
        elsif Gon.send(:current_gon)
          variable = {}
          @watch_variables ||= {}
          env = Gon.send(:current_gon).env
          variable['url'] = env['ORIGINAL_FULLPATH'] || env['REQUEST_URI']
          variable['method'] = env['REQUEST_METHOD']
          variable['name'] = name

          @watch_variables[name] = variable
          super
        end
      end

      def return_variable?(variable)
        controller = Gon::EnvFinder.controller_env
        params = controller.params
        variable = variable.to_s.gsub('=', '')

        controller.request.xhr? &&
          params[:gon_return_variable] &&
          params[:gon_watched_variable] == variable
      end

      def return_variable(value)
        controller = Gon::EnvFinder.controller_env
        controller.render json: Gon::Escaper.escape_unicode(Gon::JsonDumper.dump value)
      end

    end
  end
end
