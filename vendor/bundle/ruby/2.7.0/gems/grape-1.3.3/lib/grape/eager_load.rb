# frozen_string_literal: true

Grape.eager_load!
Grape::Http.eager_load!
Grape::Exceptions.eager_load!
Grape::Extensions.eager_load!
Grape::Extensions::ActiveSupport.eager_load!
Grape::Extensions::Hashie.eager_load!
Grape::Middleware.eager_load!
Grape::Middleware::Auth.eager_load!
Grape::Middleware::Versioner.eager_load!
Grape::Util.eager_load!
Grape::ErrorFormatter.eager_load!
Grape::Formatter.eager_load!
Grape::Parser.eager_load!
Grape::DSL.eager_load!
Grape::API.eager_load!
Grape::Presenters.eager_load!
Grape::ServeFile.eager_load!
Rack::Head # AutoLoads the Rack::Head
