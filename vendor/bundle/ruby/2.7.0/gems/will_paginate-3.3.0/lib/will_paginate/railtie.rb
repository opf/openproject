require 'will_paginate/page_number'
require 'will_paginate/collection'
require 'will_paginate/i18n'

module WillPaginate
  class Railtie < Rails::Railtie
    initializer "will_paginate" do |app|
      ActiveSupport.on_load :active_record do
        require 'will_paginate/active_record'
      end

      ActiveSupport.on_load :action_controller do
        WillPaginate::Railtie.setup_actioncontroller
      end

      ActiveSupport.on_load :action_view do
        require 'will_paginate/view_helpers/action_view'
      end

      # early access to ViewHelpers.pagination_options
      require 'will_paginate/view_helpers'
    end

    def self.setup_actioncontroller
      ( defined?(ActionDispatch::ExceptionWrapper) ?
        ActionDispatch::ExceptionWrapper : ActionDispatch::ShowExceptions
      ).send :include, ShowExceptionsPatch
      ActionController::Base.extend ControllerRescuePatch
    end

    # Extending the exception handler middleware so it properly detects
    # WillPaginate::InvalidPage regardless of it being a tag module.
    module ShowExceptionsPatch
      extend ActiveSupport::Concern
      included do
        alias_method :status_code_without_paginate, :status_code
        alias_method :status_code, :status_code_with_paginate
      end
      def status_code_with_paginate(exception = @exception)
        actual_exception = if exception.respond_to?(:cause)
          exception.cause || exception
        elsif exception.respond_to?(:original_exception)
          exception.original_exception
        else
          exception
        end

        if actual_exception.is_a?(WillPaginate::InvalidPage)
          Rack::Utils.status_code(:not_found)
        else
          original_method = method(:status_code_without_paginate)
          if original_method.arity != 0
            original_method.call(exception)
          else
            original_method.call()
          end
        end
      end
    end

    module ControllerRescuePatch
      def rescue_from(*args, **kwargs, &block)
        if idx = args.index(WillPaginate::InvalidPage)
          args[idx] = args[idx].name
        end
        super(*args, **kwargs, &block)
      end
    end
  end
end

ActiveSupport.on_load :i18n do
  I18n.load_path.concat(WillPaginate::I18n.load_path)
end
