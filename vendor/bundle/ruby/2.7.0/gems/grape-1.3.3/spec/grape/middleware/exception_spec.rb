# frozen_string_literal: true

require 'spec_helper'

describe Grape::Middleware::Error do
  # raises a text exception
  module ExceptionSpec
    class ExceptionApp
      class << self
        def call(_env)
          raise 'rain!'
        end
      end
    end

    # raises a non-StandardError (ScriptError) exception
    class OtherExceptionApp
      class << self
        def call(_env)
          raise NotImplementedError, 'snow!'
        end
      end
    end

    # raises a hash error
    class ErrorHashApp
      class << self
        def error!(message, status)
          throw :error, message: { error: message, detail: 'missing widget' }, status: status
        end

        def call(_env)
          error!('rain!', 401)
        end
      end
    end

    # raises an error!
    class AccessDeniedApp
      class << self
        def error!(message, status)
          throw :error, message: message, status: status
        end

        def call(_env)
          error!('Access Denied', 401)
        end
      end
    end

    # raises a custom error
    class CustomError < Grape::Exceptions::Base
    end

    class CustomErrorApp
      class << self
        def call(_env)
          raise CustomError.new(status: 400, message: 'failed validation')
        end
      end
    end
  end

  def app
    subject
  end

  context 'with defaults' do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'does not trap errors by default' do
      expect { get '/' }.to raise_error(RuntimeError, 'rain!')
    end
  end

  context 'with rescue_all' do
    context 'StandardError exception' do
      subject do
        Rack::Builder.app do
          use Spec::Support::EndpointFaker
          use Grape::Middleware::Error, rescue_all: true
          run ExceptionSpec::ExceptionApp
        end
      end
      it 'sets the message appropriately' do
        get '/'
        expect(last_response.body).to eq('rain!')
      end
      it 'defaults to a 500 status' do
        get '/'
        expect(last_response.status).to eq(500)
      end
    end

    context 'Non-StandardError exception' do
      subject do
        Rack::Builder.app do
          use Spec::Support::EndpointFaker
          use Grape::Middleware::Error, rescue_all: true
          run ExceptionSpec::OtherExceptionApp
        end
      end
      it 'does not trap errors other than StandardError' do
        expect { get '/' }.to raise_error(NotImplementedError, 'snow!')
      end
    end
  end

  context 'Non-StandardError exception with a provided rescue handler' do
    context 'default error response' do
      subject do
        Rack::Builder.app do
          use Spec::Support::EndpointFaker
          use Grape::Middleware::Error, rescue_handlers: { NotImplementedError => nil }
          run ExceptionSpec::OtherExceptionApp
        end
      end
      it 'rescues the exception using the default handler' do
        get '/'
        expect(last_response.body).to eq('snow!')
      end
    end

    context 'custom error response' do
      subject do
        Rack::Builder.app do
          use Spec::Support::EndpointFaker
          use Grape::Middleware::Error, rescue_handlers: { NotImplementedError => -> { Rack::Response.new('rescued', 200, {}) } }
          run ExceptionSpec::OtherExceptionApp
        end
      end
      it 'rescues the exception using the provided handler' do
        get '/'
        expect(last_response.body).to eq('rescued')
      end
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, default_status: 500
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to specify a different default status code' do
      get '/'
      expect(last_response.status).to eq(500)
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :json
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to return errors in json format' do
      get '/'
      expect(last_response.body).to eq('{"error":"rain!"}')
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :json
        run ExceptionSpec::ErrorHashApp
      end
    end
    it 'is possible to return hash errors in json format' do
      get '/'
      expect(['{"error":"rain!","detail":"missing widget"}',
              '{"detail":"missing widget","error":"rain!"}']).to include(last_response.body)
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :jsonapi
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to return errors in jsonapi format' do
      get '/'
      expect(last_response.body).to eq('{&quot;error&quot;:&quot;rain!&quot;}')
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :jsonapi
        run ExceptionSpec::ErrorHashApp
      end
    end

    it 'is possible to return hash errors in jsonapi format' do
      get '/'
      expect(['{&quot;error&quot;:&quot;rain!&quot;,&quot;detail&quot;:&quot;missing widget&quot;}',
              '{&quot;detail&quot;:&quot;missing widget&quot;,&quot;error&quot;:&quot;rain!&quot;}']).to include(last_response.body)
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :xml
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to return errors in xml format' do
      get '/'
      expect(last_response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <message>rain!</message>\n</error>\n")
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: true, format: :xml
        run ExceptionSpec::ErrorHashApp
      end
    end
    it 'is possible to return hash errors in xml format' do
      get '/'
      expect(["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <detail>missing widget</detail>\n  <error>rain!</error>\n</error>\n",
              "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <error>rain!</error>\n  <detail>missing widget</detail>\n</error>\n"]).to include(last_response.body)
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error,
            rescue_all: true,
            format: :custom,
            error_formatters: {
              custom: lambda do |message, _backtrace, _options, _env, _original_exception|
                { custom_formatter: message }.inspect
              end
            }
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to specify a custom formatter' do
      get '/'
      expect(last_response.body).to eq('{:custom_formatter=&gt;&quot;rain!&quot;}')
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error
        run ExceptionSpec::AccessDeniedApp
      end
    end
    it 'does not trap regular error! codes' do
      get '/'
      expect(last_response.status).to eq(401)
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error, rescue_all: false
        run ExceptionSpec::CustomErrorApp
      end
    end
    it 'responds to custom Grape exceptions appropriately' do
      get '/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('failed validation')
    end
  end

  context 'with rescue_options :backtrace and :exception set to true' do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error,
            rescue_all: true,
            format: :json,
            rescue_options: { backtrace: true, original_exception: true }
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to return the backtrace and the original exception in json format' do
      get '/'
      expect(last_response.body).to include('error', 'rain!', 'backtrace', 'original_exception', 'RuntimeError')
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error,
            rescue_all: true,
            format: :xml,
            rescue_options: { backtrace: true, original_exception: true }
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to return the backtrace and the original exception in xml format' do
      get '/'
      expect(last_response.body).to include('error', 'rain!', 'backtrace', 'original-exception', 'RuntimeError')
    end
  end

  context do
    subject do
      Rack::Builder.app do
        use Spec::Support::EndpointFaker
        use Grape::Middleware::Error,
            rescue_all: true,
            format: :txt,
            rescue_options: { backtrace: true, original_exception: true }
        run ExceptionSpec::ExceptionApp
      end
    end
    it 'is possible to return the backtrace and the original exception in txt format' do
      get '/'
      expect(last_response.body).to include('error', 'rain!', 'backtrace', 'original exception', 'RuntimeError')
    end
  end
end
