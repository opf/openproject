# frozen_string_literal: true

require 'spec_helper'
require 'shared/versioning_examples'

describe Grape::API do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '.prefix' do
    it 'routes root through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get do
        'Hello there.'
      end

      get 'awesome/sauce/'
      expect(last_response.status).to eql 200
      expect(last_response.body).to eql 'Hello there.'
    end

    it 'routes through with the prefix' do
      subject.prefix 'awesome/sauce'
      subject.get :hello do
        'Hello there.'
      end

      get 'awesome/sauce/hello'
      expect(last_response.body).to eql 'Hello there.'

      get '/hello'
      expect(last_response.status).to eql 404
    end

    it 'supports OPTIONS' do
      subject.prefix 'awesome/sauce'
      subject.get do
        'Hello there.'
      end

      options 'awesome/sauce'
      expect(last_response.status).to eql 204
      expect(last_response.body).to be_blank
    end

    it 'disallows POST' do
      subject.prefix 'awesome/sauce'
      subject.get

      post 'awesome/sauce'
      expect(last_response.status).to eql 405
    end
  end

  describe '.version' do
    context 'when defined' do
      it 'returns version value' do
        subject.version 'v1'
        expect(subject.version).to eq('v1')
      end
    end

    context 'when not defined' do
      it 'returns nil' do
        expect(subject.version).to be_nil
      end
    end
  end

  describe '.version using path' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :path
        }
      end
    end
  end

  describe '.version using param' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :param,
          parameter: 'apiver'
        }
      end
    end
  end

  describe '.version using header' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :header,
          vendor: 'mycompany',
          format: 'json'
        }
      end
    end

    # Behavior as defined by rfc2616 when no header is defined
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
    describe 'no specified accept header' do
      # subject.version 'v1', using: :header
      # subject.get '/hello' do
      #   'hello'
      # end

      # it 'routes' do
      #   get '/hello'
      #   last_response.status.should eql 200
      # end
    end

    # pending 'routes if any media type is allowed'
  end

  describe '.version using accept_version_header' do
    it_should_behave_like 'versioning' do
      let(:macro_options) do
        {
          using: :accept_version_header
        }
      end
    end
  end

  describe '.represent' do
    it 'requires a :with option' do
      expect { subject.represent Object, {} }.to raise_error(Grape::Exceptions::InvalidWithOptionForRepresent)
    end

    it 'adds the association to the :representations setting' do
      klass = Class.new
      subject.represent Object, with: klass
      expect(subject.namespace_stackable_with_hash(:representations)[Object]).to eq(klass)
    end
  end

  describe '.namespace' do
    it 'is retrievable and converted to a path' do
      internal_namespace = nil
      subject.namespace :awesome do
        internal_namespace = namespace
      end
      expect(internal_namespace).to eql('/awesome')
    end

    it 'comes after the prefix and version' do
      subject.prefix :rad
      subject.version 'v1', using: :path

      subject.namespace :awesome do
        get('/hello') { 'worked' }
      end

      get '/rad/v1/awesome/hello'
      expect(last_response.body).to eq('worked')
    end

    it 'cancels itself after the block is over' do
      internal_namespace = nil
      subject.namespace :awesome do
        internal_namespace = namespace
      end
      expect(subject.namespace).to eql('/')
    end

    it 'is stackable' do
      internal_namespace = nil
      internal_second_namespace = nil
      subject.namespace :awesome do
        internal_namespace = namespace
        namespace :rad do
          internal_second_namespace = namespace
        end
      end
      expect(internal_namespace).to eq('/awesome')
      expect(internal_second_namespace).to eq('/awesome/rad')
    end

    it 'accepts path segments correctly' do
      inner_namespace = nil
      subject.namespace :members do
        namespace '/:member_id' do
          inner_namespace = namespace
          get '/' do
            params[:member_id]
          end
        end
      end
      get '/members/23'
      expect(last_response.body).to eq('23')
      expect(inner_namespace).to eq('/members/:member_id')
    end

    it 'is callable with nil just to push onto the stack' do
      subject.namespace do
        version 'v2', using: :path
        get('/hello') { 'inner' }
      end
      subject.get('/hello') { 'outer' }

      get '/v2/hello'
      expect(last_response.body).to eq('inner')
      get '/hello'
      expect(last_response.body).to eq('outer')
    end

    %w[group resource resources segment].each do |als|
      it "`.#{als}` is an alias" do
        inner_namespace = nil
        subject.send(als, :awesome) do
          inner_namespace = namespace
        end
        expect(inner_namespace).to eq '/awesome'
      end
    end
  end

  describe '.call' do
    context 'it does not add to the app setup' do
      it 'calls the app' do
        expect(subject).not_to receive(:add_setup)
        subject.call({})
      end
    end
  end

  describe '.route_param' do
    it 'adds a parameterized route segment namespace' do
      subject.namespace :users do
        route_param :id do
          get do
            params[:id]
          end
        end
      end

      get '/users/23'
      expect(last_response.body).to eq('23')
    end

    it 'defines requirements with a single hash' do
      subject.namespace :users do
        route_param :id, requirements: /[0-9]+/ do
          get do
            params[:id]
          end
        end
      end

      get '/users/michael'
      expect(last_response.status).to eq(404)
      get '/users/23'
      expect(last_response.status).to eq(200)
    end

    context 'with param type definitions' do
      it 'is used by passing to options' do
        subject.namespace :route_param do
          route_param :foo, type: Integer do
            get { params.to_json }
          end
        end
        get '/route_param/1234'
        expect(last_response.body).to eq('{"foo":1234}')
      end
    end
  end

  describe '.route' do
    it 'allows for no path' do
      subject.namespace :votes do
        get do
          'Votes'
        end
        post do
          'Created a Vote'
        end
      end

      get '/votes'
      expect(last_response.body).to eql 'Votes'
      post '/votes'
      expect(last_response.body).to eql 'Created a Vote'
    end

    it 'handles empty calls' do
      subject.get '/'
      get '/'
      expect(last_response.body).to eql ''
    end

    describe 'root routes should work with' do
      before do
        subject.format :txt
        subject.content_type :json, 'application/json'
        subject.formatter :json, ->(object, _env) { object }
        def subject.enable_root_route!
          get('/') { 'root' }
        end
      end

      after do
        expect(last_response.body).to eql 'root'
      end

      describe 'path versioned APIs' do
        before do
          subject.version version, using: :path
          subject.enable_root_route!
        end

        context 'when a single version provided' do
          let(:version) { 'v1' }

          it 'without a format' do
            versioned_get '/', 'v1', using: :path
          end

          it 'with a format' do
            get '/v1/.json'
          end
        end

        context 'when array of versions provided' do
          let(:version) { %w[v1 v2] }

          it { versioned_get '/', 'v1', using: :path }
          it { versioned_get '/', 'v2', using: :path }
        end
      end

      it 'header versioned APIs' do
        subject.version 'v1', using: :header, vendor: 'test'
        subject.enable_root_route!

        versioned_get '/', 'v1', using: :header, vendor: 'test'
      end

      it 'header versioned APIs with multiple headers' do
        subject.version %w[v1 v2], using: :header, vendor: 'test'
        subject.enable_root_route!

        versioned_get '/', 'v1', using: :header, vendor: 'test'
        versioned_get '/', 'v2', using: :header, vendor: 'test'
      end

      it 'param versioned APIs' do
        subject.version 'v1', using: :param
        subject.enable_root_route!

        versioned_get '/', 'v1', using: :param
      end

      it 'Accept-Version header versioned APIs' do
        subject.version 'v1', using: :accept_version_header
        subject.enable_root_route!

        versioned_get '/', 'v1', using: :accept_version_header
      end

      it 'unversioned APIs' do
        subject.enable_root_route!

        get '/'
      end
    end

    it 'allows for multiple paths' do
      subject.get(['/abc', '/def']) do
        'foo'
      end

      get '/abc'
      expect(last_response.body).to eql 'foo'
      get '/def'
      expect(last_response.body).to eql 'foo'
    end

    context 'format' do
      module ApiSpec
        class DummyFormatClass
        end
      end

      before(:each) do
        allow_any_instance_of(ApiSpec::DummyFormatClass).to receive(:to_json).and_return('abc')
        allow_any_instance_of(ApiSpec::DummyFormatClass).to receive(:to_txt).and_return('def')

        subject.get('/abc') do
          ApiSpec::DummyFormatClass.new
        end
      end

      it 'allows .json' do
        get '/abc.json'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eql 'abc' # json-encoded symbol
      end

      it 'allows .txt' do
        get '/abc.txt'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eql 'def' # raw text
      end
    end

    it 'allows for format without corrupting a param' do
      subject.get('/:id') do
        { 'id' => params[:id] }
      end

      get '/awesome.json'
      expect(last_response.body).to eql '{"id":"awesome"}'
    end

    it 'allows for format in namespace with no path' do
      subject.namespace :abc do
        get do
          ['json']
        end
      end

      get '/abc.json'
      expect(last_response.body).to eql '["json"]'
    end

    it 'allows for multiple verbs' do
      subject.route(%i[get post], '/abc') do
        'hiya'
      end

      subject.endpoints.first.routes.each do |route|
        expect(route.path).to eql '/abc(.:format)'
      end

      get '/abc'
      expect(last_response.body).to eql 'hiya'
      post '/abc'
      expect(last_response.body).to eql 'hiya'
    end

    %i[put post].each do |verb|
      context verb do
        ['string', :symbol, 1, -1.1, {}, [], true, false, nil].each do |object|
          it "allows a(n) #{object.class} json object in params" do
            subject.format :json
            subject.send(verb) do
              env['api.request.body']
            end
            send verb, '/', ::Grape::Json.dump(object), 'CONTENT_TYPE' => 'application/json'
            expect(last_response.status).to eq(verb == :post ? 201 : 200)
            expect(last_response.body).to eql ::Grape::Json.dump(object)
            expect(last_request.params).to eql({})
          end
          it 'stores input in api.request.input' do
            subject.format :json
            subject.send(verb) do
              env['api.request.input']
            end
            send verb, '/', ::Grape::Json.dump(object), 'CONTENT_TYPE' => 'application/json'
            expect(last_response.status).to eq(verb == :post ? 201 : 200)
            expect(last_response.body).to eql ::Grape::Json.dump(object).to_json
          end
          context 'chunked transfer encoding' do
            it 'stores input in api.request.input' do
              subject.format :json
              subject.send(verb) do
                env['api.request.input']
              end
              send verb, '/', ::Grape::Json.dump(object), 'CONTENT_TYPE' => 'application/json', 'HTTP_TRANSFER_ENCODING' => 'chunked', 'CONTENT_LENGTH' => nil
              expect(last_response.status).to eq(verb == :post ? 201 : 200)
              expect(last_response.body).to eql ::Grape::Json.dump(object).to_json
            end
          end
        end
      end
    end

    it 'allows for multipart paths' do
      subject.route(%i[get post], '/:id/first') do
        'first'
      end

      subject.route(%i[get post], '/:id') do
        'ola'
      end
      subject.route(%i[get post], '/:id/first/second') do
        'second'
      end

      get '/1'
      expect(last_response.body).to eql 'ola'
      post '/1'
      expect(last_response.body).to eql 'ola'
      get '/1/first'
      expect(last_response.body).to eql 'first'
      post '/1/first'
      expect(last_response.body).to eql 'first'
      get '/1/first/second'
      expect(last_response.body).to eql 'second'
    end

    it 'allows for :any as a verb' do
      subject.route(:any, '/abc') do
        'lol'
      end

      %w[get post put delete options patch].each do |m|
        send(m, '/abc')
        expect(last_response.body).to eql 'lol'
      end
    end

    it 'allows for catch-all in a namespace' do
      subject.namespace :nested do
        get do
          'root'
        end

        get 'something' do
          'something'
        end

        route :any, '*path' do
          'catch-all'
        end
      end

      get 'nested'
      expect(last_response.body).to eql 'root'

      get 'nested/something'
      expect(last_response.body).to eql 'something'

      get 'nested/missing'
      expect(last_response.body).to eql 'catch-all'

      post 'nested'
      expect(last_response.body).to eql 'catch-all'

      post 'nested/something'
      expect(last_response.body).to eql 'catch-all'
    end

    verbs = %w[post get head delete put options patch]
    verbs.each do |verb|
      it "allows and properly constrain a #{verb.upcase} method" do
        subject.send(verb, '/example') do
          verb
        end
        send(verb, '/example')
        expect(last_response.body).to eql verb == 'head' ? '' : verb
        # Call it with all methods other than the properly constrained one.
        (verbs - [verb]).each do |other_verb|
          send(other_verb, '/example')
          expected_rc = if other_verb == 'options' then 204
                        elsif other_verb == 'head' && verb == 'get' then 200
                        else 405
                        end
          expect(last_response.status).to eql expected_rc
        end
      end
    end

    it 'returns a 201 response code for POST by default' do
      subject.post('example') do
        'Created'
      end

      post '/example'
      expect(last_response.status).to eql 201
      expect(last_response.body).to eql 'Created'
    end

    it 'returns a 405 for an unsupported method with an X-Custom-Header' do
      subject.before { header 'X-Custom-Header', 'foo' }
      subject.get 'example' do
        'example'
      end
      put '/example'
      expect(last_response.status).to eql 405
      expect(last_response.body).to eql '405 Not Allowed'
      expect(last_response.headers['X-Custom-Header']).to eql 'foo'
    end

    it 'runs only the before filter on 405 bad method' do
      subject.namespace :example do
        before            { header 'X-Custom-Header', 'foo' }
        before_validation { raise 'before_validation filter should not run' }
        after_validation  { raise 'after_validation filter should not run' }
        after             { raise 'after filter should not run' }
        params { requires :only_for_get }
        get
      end

      post '/example'
      expect(last_response.status).to eql 405
      expect(last_response.headers['X-Custom-Header']).to eql 'foo'
    end

    it 'runs before filter exactly once on 405 bad method' do
      already_run = false
      subject.namespace :example do
        before do
          raise 'before filter ran twice' if already_run
          already_run = true
          header 'X-Custom-Header', 'foo'
        end
        get
      end

      post '/example'
      expect(last_response.status).to eql 405
      expect(last_response.headers['X-Custom-Header']).to eql 'foo'
    end

    it 'runs all filters and body with a custom OPTIONS method' do
      subject.namespace :example do
        before            { header 'X-Custom-Header-1', 'foo' }
        before_validation { header 'X-Custom-Header-2', 'foo' }
        after_validation  { header 'X-Custom-Header-3', 'foo' }
        after             { header 'X-Custom-Header-4', 'foo' }
        options { 'yup' }
        get
      end

      options '/example'
      expect(last_response.status).to eql 200
      expect(last_response.body).to eql 'yup'
      expect(last_response.headers['Allow']).to be_nil
      expect(last_response.headers['X-Custom-Header-1']).to eql 'foo'
      expect(last_response.headers['X-Custom-Header-2']).to eql 'foo'
      expect(last_response.headers['X-Custom-Header-3']).to eql 'foo'
      expect(last_response.headers['X-Custom-Header-4']).to eql 'foo'
    end

    context 'when format is xml' do
      it 'returns a 405 for an unsupported method' do
        subject.format :xml
        subject.get 'example' do
          'example'
        end

        put '/example'
        expect(last_response.status).to eql 405
        expect(last_response.body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<error>
  <message>405 Not Allowed</message>
</error>
XML
      end
    end

    context 'when accessing env' do
      it 'returns a 405 for an unsupported method' do
        subject.before do
          _customheader1 = headers['X-Custom-Header']
          _customheader2 = env['HTTP_X_CUSTOM_HEADER']
        end
        subject.get 'example' do
          'example'
        end
        put '/example'
        expect(last_response.status).to eql 405
        expect(last_response.body).to eql '405 Not Allowed'
      end
    end

    specify '405 responses includes an Allow header specifying supported methods' do
      subject.get 'example' do
        'example'
      end
      subject.post 'example' do
        'example'
      end
      put '/example'
      expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, POST, HEAD'
    end

    specify '405 responses includes an Content-Type header' do
      subject.get 'example' do
        'example'
      end
      subject.post 'example' do
        'example'
      end
      put '/example'
      expect(last_response.headers['Content-Type']).to eql 'text/plain'
    end

    describe 'adds an OPTIONS route that' do
      before do
        subject.before            { header 'X-Custom-Header', 'foo' }
        subject.before_validation { header 'X-Custom-Header-2', 'bar' }
        subject.after_validation  { header 'X-Custom-Header-3', 'baz' }
        subject.after             { header 'X-Custom-Header-4', 'bing' }
        subject.params { requires :only_for_get }
        subject.get 'example' do
          'example'
        end
        subject.route :any, '*path' do
          error! :not_found, 404
        end
        options '/example'
      end

      it 'returns a 204' do
        expect(last_response.status).to eql 204
      end

      it 'has an empty body' do
        expect(last_response.body).to be_blank
      end

      it 'has an Allow header' do
        expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, HEAD'
      end

      it 'calls before hook' do
        expect(last_response.headers['X-Custom-Header']).to eql 'foo'
      end

      it 'does not call before_validation hook' do
        expect(last_response.headers.key?('X-Custom-Header-2')).to be false
      end

      it 'does not call after_validation hook' do
        expect(last_response.headers.key?('X-Custom-Header-3')).to be false
      end

      it 'calls after hook' do
        expect(last_response.headers['X-Custom-Header-4']).to eq 'bing'
      end

      it 'has no Content-Type' do
        expect(last_response.content_type).to be_nil
      end

      it 'has no Content-Length' do
        expect(last_response.content_length).to be_nil
      end
    end

    describe 'adds an OPTIONS route for namespaced endpoints that' do
      before do
        subject.before { header 'X-Custom-Header', 'foo' }
        subject.namespace :example do
          before { header 'X-Custom-Header-2', 'foo' }
          get :inner do
            'example/inner'
          end
        end
        options '/example/inner'
      end

      it 'returns a 204' do
        expect(last_response.status).to eql 204
      end

      it 'has an empty body' do
        expect(last_response.body).to be_blank
      end

      it 'has an Allow header' do
        expect(last_response.headers['Allow']).to eql 'OPTIONS, GET, HEAD'
      end

      it 'calls the outer before filter' do
        expect(last_response.headers['X-Custom-Header']).to eql 'foo'
      end

      it 'calls the inner before filter' do
        expect(last_response.headers['X-Custom-Header-2']).to eql 'foo'
      end

      it 'has no Content-Type' do
        expect(last_response.content_type).to be_nil
      end

      it 'has no Content-Length' do
        expect(last_response.content_length).to be_nil
      end
    end

    describe 'adds a 405 Not Allowed route that' do
      before do
        subject.before { header 'X-Custom-Header', 'foo' }
        subject.post :example do
          'example'
        end
        get '/example'
      end

      it 'returns a 405' do
        expect(last_response.status).to eql 405
      end

      it 'contains error message in body' do
        expect(last_response.body).to eq '405 Not Allowed'
      end

      it 'has an Allow header' do
        expect(last_response.headers['Allow']).to eql 'OPTIONS, POST'
      end

      it 'has a X-Custom-Header' do
        expect(last_response.headers['X-Custom-Header']).to eql 'foo'
      end
    end

    context 'allows HEAD on a GET request that' do
      before do
        subject.get 'example' do
          'example'
        end
        subject.route :any, '*path' do
          error! :not_found, 404
        end
        head '/example'
      end

      it 'returns a 200' do
        expect(last_response.status).to eql 200
      end

      it 'has an empty body' do
        expect(last_response.body).to eql ''
      end
    end

    it 'overwrites the default HEAD request' do
      subject.head 'example' do
        error! 'nothing to see here', 400
      end
      subject.get 'example' do
        'example'
      end
      head '/example'
      expect(last_response.status).to eql 400
    end
  end

  context 'do_not_route_head!' do
    before :each do
      subject.do_not_route_head!
      subject.get 'example' do
        'example'
      end
    end
    it 'options does not contain HEAD' do
      options '/example'
      expect(last_response.status).to eql 204
      expect(last_response.body).to eql ''
      expect(last_response.headers['Allow']).to eql 'OPTIONS, GET'
    end
    it 'does not allow HEAD on a GET request' do
      head '/example'
      expect(last_response.status).to eql 405
    end
  end

  context 'do_not_route_options!' do
    before :each do
      subject.do_not_route_options!
      subject.get 'example' do
        'example'
      end
    end

    it 'does not create an OPTIONS route' do
      options '/example'
      expect(last_response.status).to eql 405
    end

    it 'does not include OPTIONS in Allow header' do
      options '/example'
      expect(last_response.status).to eql 405
      expect(last_response.headers['Allow']).to eql 'GET, HEAD'
    end
  end

  describe '.compile!' do
    it 'requires the grape/eager_load file' do
      expect(app).to receive(:require).with('grape/eager_load') { nil }
      app.compile!
    end

    it 'compiles the instance for rack!' do
      stubbed_object = double(:instance_for_rack)
      allow(app).to receive(:instance_for_rack) { stubbed_object }
    end
  end

  # NOTE: this method is required to preserve the ability of pre-mounting
  # the root API into a namespace, it may be deprecated in the future.
  describe 'instance_for_rack' do
    context 'when the app was not mounted' do
      it 'returns the base_instance' do
        expect(app.send(:instance_for_rack)).to eq app.base_instance
      end
    end

    context 'when the app was mounted' do
      it 'returns the first mounted instance' do
        mounted_app = app
        Class.new(Grape::API) do
          namespace 'new_namespace' do
            mount mounted_app
          end
        end
        expect(app.send(:instance_for_rack)).to eq app.send(:mounted_instances).first
      end
    end
  end

  describe 'filters' do
    it 'adds a before filter' do
      subject.before { @foo = 'first'  }
      subject.before { @bar = 'second' }
      subject.get '/' do
        "#{@foo} #{@bar}"
      end

      get '/'
      expect(last_response.body).to eql 'first second'
    end

    it 'adds a before filter to current and child namespaces only' do
      subject.get '/' do
        "root - #{instance_variable_defined?(:@foo) ? @foo : nil}"
      end
      subject.namespace :blah do
        before { @foo = 'foo' }
        get '/' do
          "blah - #{@foo}"
        end

        namespace :bar do
          get '/' do
            "blah - bar - #{@foo}"
          end
        end
      end

      get '/'
      expect(last_response.body).to eql 'root - '
      get '/blah'
      expect(last_response.body).to eql 'blah - foo'
      get '/blah/bar'
      expect(last_response.body).to eql 'blah - bar - foo'
    end

    it 'adds a after_validation filter' do
      subject.after_validation { @foo = "first #{params[:id]}:#{params[:id].class}" }
      subject.after_validation { @bar = 'second' }
      subject.params do
        requires :id, type: Integer
      end
      subject.get '/' do
        "#{@foo} #{@bar}"
      end

      get '/', id: '32'
      expect(last_response.body).to eql "first 32:#{integer_class_name} second"
    end

    it 'adds a after filter' do
      m = double('after mock')
      subject.after { m.do_something! }
      subject.after { m.do_something! }
      subject.get '/' do
        @var ||= 'default'
      end

      expect(m).to receive(:do_something!).exactly(2).times
      get '/'
      expect(last_response.body).to eql 'default'
    end

    it 'calls all filters when validation passes' do
      a = double('before mock')
      b = double('before_validation mock')
      c = double('after_validation mock')
      d = double('after mock')

      subject.params do
        requires :id, type: Integer
      end
      subject.resource ':id' do
        before { a.do_something! }
        before_validation { b.do_something! }
        after_validation { c.do_something! }
        after { d.do_something! }
        get do
          'got it'
        end
      end

      expect(a).to receive(:do_something!).exactly(1).times
      expect(b).to receive(:do_something!).exactly(1).times
      expect(c).to receive(:do_something!).exactly(1).times
      expect(d).to receive(:do_something!).exactly(1).times

      get '/123'
      expect(last_response.status).to eql 200
      expect(last_response.body).to eql 'got it'
    end

    it 'calls only before filters when validation fails' do
      a = double('before mock')
      b = double('before_validation mock')
      c = double('after_validation mock')
      d = double('after mock')

      subject.params do
        requires :id, type: Integer
      end
      subject.resource ':id' do
        before { a.do_something! }
        before_validation { b.do_something! }
        after_validation { c.do_something! }
        after { d.do_something! }
        get do
          'got it'
        end
      end

      expect(a).to receive(:do_something!).exactly(1).times
      expect(b).to receive(:do_something!).exactly(1).times
      expect(c).to receive(:do_something!).exactly(0).times
      expect(d).to receive(:do_something!).exactly(0).times

      get '/abc'
      expect(last_response.status).to eql 400
      expect(last_response.body).to eql 'id is invalid'
    end

    it 'calls filters in the correct order' do
      i = 0
      a = double('before mock')
      b = double('before_validation mock')
      c = double('after_validation mock')
      d = double('after mock')

      subject.params do
        requires :id, type: Integer
      end
      subject.resource ':id' do
        before { a.here(i += 1) }
        before_validation { b.here(i += 1) }
        after_validation { c.here(i += 1) }
        after { d.here(i += 1) }
        get do
          'got it'
        end
      end

      expect(a).to receive(:here).with(1).exactly(1).times
      expect(b).to receive(:here).with(2).exactly(1).times
      expect(c).to receive(:here).with(3).exactly(1).times
      expect(d).to receive(:here).with(4).exactly(1).times

      get '/123'
      expect(last_response.status).to eql 200
      expect(last_response.body).to eql 'got it'
    end
  end

  context 'format' do
    before do
      subject.get('/foo') { 'bar' }
    end

    it 'sets content type for txt format' do
      get '/foo'
      expect(last_response.headers['Content-Type']).to eq('text/plain')
    end

    it 'sets content type for xml' do
      get '/foo.xml'
      expect(last_response.headers['Content-Type']).to eq('application/xml')
    end

    it 'sets content type for json' do
      get '/foo.json'
      expect(last_response.headers['Content-Type']).to eq('application/json')
    end

    it 'sets content type for serializable hash format' do
      get '/foo.serializable_hash'
      expect(last_response.headers['Content-Type']).to eq('application/json')
    end

    it 'sets content type for binary format' do
      get '/foo.binary'
      expect(last_response.headers['Content-Type']).to eq('application/octet-stream')
    end

    it 'returns raw data when content type binary' do
      image_filename = 'grape.png'
      file = File.open(image_filename, 'rb', &:read)
      subject.format :binary
      subject.get('/binary_file') { File.binread(image_filename) }
      get '/binary_file'
      expect(last_response.headers['Content-Type']).to eq('application/octet-stream')
      expect(last_response.body).to eq(file)
    end

    it 'returns the content of the file with file' do
      file_content = 'This is some file content'
      test_file = Tempfile.new('test')
      test_file.write file_content
      test_file.rewind

      subject.get('/file') { file test_file }
      get '/file'
      expect(last_response.headers['Content-Length']).to eq('25')
      expect(last_response.headers['Content-Type']).to eq('text/plain')
      expect(last_response.body).to eq(file_content)
    end

    it 'streams the content of the file with stream' do
      test_stream = Enumerator.new do |blk|
        blk.yield 'This is some'
        blk.yield ' file content'
      end

      subject.use Rack::Chunked
      subject.get('/stream') { stream test_stream }
      get '/stream', {}, 'HTTP_VERSION' => 'HTTP/1.1', 'SERVER_PROTOCOL' => 'HTTP/1.1'

      expect(last_response.headers['Content-Type']).to eq('text/plain')
      expect(last_response.headers['Content-Length']).to eq(nil)
      expect(last_response.headers['Cache-Control']).to eq('no-cache')
      expect(last_response.headers['Transfer-Encoding']).to eq('chunked')

      expect(last_response.body).to eq("c\r\nThis is some\r\nd\r\n file content\r\n0\r\n\r\n")
    end

    it 'sets content type for error' do
      subject.get('/error') { error!('error in plain text', 500) }
      get '/error'
      expect(last_response.headers['Content-Type']).to eql 'text/plain'
    end

    it 'sets content type for json error' do
      subject.format :json
      subject.get('/error') { error!('error in json', 500) }
      get '/error.json'
      expect(last_response.status).to eql 500
      expect(last_response.headers['Content-Type']).to eql 'application/json'
    end

    it 'sets content type for xml error' do
      subject.format :xml
      subject.get('/error') { error!('error in xml', 500) }
      get '/error'
      expect(last_response.status).to eql 500
      expect(last_response.headers['Content-Type']).to eql 'application/xml'
    end

    it 'includes extension in format' do
      subject.get(':id') { params[:format] }

      get '/baz.bar'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bar'
    end

    it 'does not include extension in id' do
      subject.format :json
      subject.get(':id') { params }

      get '/baz.bar'
      expect(last_response.status).to eq 404
    end

    context 'with a custom content_type' do
      before do
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, ->(_object, _env) { 'custom' }

        subject.get('/custom') { 'bar' }
        subject.get('/error') { error!('error in custom', 500) }
      end

      it 'sets content type' do
        get '/custom.custom'
        expect(last_response.headers['Content-Type']).to eql 'application/custom'
      end

      it 'sets content type for error' do
        get '/error.custom'
        expect(last_response.headers['Content-Type']).to eql 'application/custom'
      end
    end

    context 'env["api.format"]' do
      before do
        subject.post 'attachment' do
          filename = params[:file][:filename]
          content_type MIME::Types.type_for(filename)[0].to_s
          env['api.format'] = :binary # there's no formatter for :binary, data will be returned "as is"
          header 'Content-Disposition', "attachment; filename*=UTF-8''#{CGI.escape(filename)}"
          params[:file][:tempfile].read
        end
      end

      ['/attachment.png', 'attachment'].each do |url|
        it "uploads and downloads a PNG file via #{url}" do
          image_filename = 'grape.png'
          post url, file: Rack::Test::UploadedFile.new(image_filename, 'image/png', true)
          expect(last_response.status).to eq(201)
          expect(last_response.headers['Content-Type']).to eq('image/png')
          expect(last_response.headers['Content-Disposition']).to eq("attachment; filename*=UTF-8''grape.png")
          File.open(image_filename, 'rb') do |io|
            expect(last_response.body).to eq io.read
          end
        end
      end

      it 'uploads and downloads a Ruby file' do
        filename = __FILE__
        post '/attachment.rb', file: Rack::Test::UploadedFile.new(filename, 'application/x-ruby', true)
        expect(last_response.status).to eq(201)
        expect(last_response.headers['Content-Type']).to eq('application/x-ruby')
        expect(last_response.headers['Content-Disposition']).to eq("attachment; filename*=UTF-8''api_spec.rb")
        File.open(filename, 'rb') do |io|
          expect(last_response.body).to eq io.read
        end
      end
    end
  end

  context 'custom middleware' do
    module ApiSpec
      class PhonyMiddleware
        def initialize(app, *args)
          @args = args
          @app = app
          @block = block_given? ? true : nil
        end

        def call(env)
          env['phony.args'] ||= []
          env['phony.args'] << @args
          env['phony.block'] = true if @block
          @app.call(env)
        end
      end
    end

    describe '.middleware' do
      it 'includes middleware arguments from settings' do
        subject.use ApiSpec::PhonyMiddleware, 'abc', 123
        expect(subject.middleware).to eql [[:use, ApiSpec::PhonyMiddleware, 'abc', 123]]
      end

      it 'includes all middleware from stacked settings' do
        subject.use ApiSpec::PhonyMiddleware, 123
        subject.use ApiSpec::PhonyMiddleware, 'abc'
        subject.use ApiSpec::PhonyMiddleware, 'foo'

        expect(subject.middleware).to eql [
          [:use, ApiSpec::PhonyMiddleware, 123],
          [:use, ApiSpec::PhonyMiddleware, 'abc'],
          [:use, ApiSpec::PhonyMiddleware, 'foo']
        ]
      end
    end

    describe '.use' do
      it 'adds middleware' do
        subject.use ApiSpec::PhonyMiddleware, 123
        expect(subject.middleware).to eql [[:use, ApiSpec::PhonyMiddleware, 123]]
      end

      it 'does not show up outside the namespace' do
        inner_middleware = nil
        subject.use ApiSpec::PhonyMiddleware, 123
        subject.namespace :awesome do
          use ApiSpec::PhonyMiddleware, 'abc'
          inner_middleware = middleware
        end

        expect(subject.middleware).to eql [[:use, ApiSpec::PhonyMiddleware, 123]]
        expect(inner_middleware).to eql [[:use, ApiSpec::PhonyMiddleware, 123], [:use, ApiSpec::PhonyMiddleware, 'abc']]
      end

      it 'calls the middleware' do
        subject.use ApiSpec::PhonyMiddleware, 'hello'
        subject.get '/' do
          env['phony.args'].first.first
        end

        get '/'
        expect(last_response.body).to eql 'hello'
      end

      it 'adds a block if one is given' do
        block = -> {}
        subject.use ApiSpec::PhonyMiddleware, &block
        expect(subject.middleware).to eql [[:use, ApiSpec::PhonyMiddleware, block]]
      end

      it 'uses a block if one is given' do
        block = -> {}
        subject.use ApiSpec::PhonyMiddleware, &block
        subject.get '/' do
          env['phony.block'].inspect
        end

        get '/'
        expect(last_response.body).to eq('true')
      end

      it 'does not destroy the middleware settings on multiple runs' do
        block = -> {}
        subject.use ApiSpec::PhonyMiddleware, &block
        subject.get '/' do
          env['phony.block'].inspect
        end

        2.times do
          get '/'
          expect(last_response.body).to eq('true')
        end
      end

      it 'mounts behind error middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: 'Caught in the Net', status: 400
          end
        end
        subject.use m
        subject.get '/' do
        end
        get '/'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('Caught in the Net')
      end
    end

    describe '.insert_before' do
      it 'runs before a given middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def call(env)
            env['phony.args'] ||= []
            env['phony.args'] << @options[:message]
            @app.call(env)
          end
        end

        subject.use ApiSpec::PhonyMiddleware, 'hello'
        subject.insert_before ApiSpec::PhonyMiddleware, m, message: 'bye'
        subject.get '/' do
          env['phony.args'].join(' ')
        end

        get '/'
        expect(last_response.body).to eql 'bye hello'
      end
    end

    describe '.insert_after' do
      it 'runs after a given middleware' do
        m = Class.new(Grape::Middleware::Base) do
          def call(env)
            env['phony.args'] ||= []
            env['phony.args'] << @options[:message]
            @app.call(env)
          end
        end

        subject.use ApiSpec::PhonyMiddleware, 'hello'
        subject.insert_after ApiSpec::PhonyMiddleware, m, message: 'bye'
        subject.get '/' do
          env['phony.args'].join(' ')
        end

        get '/'
        expect(last_response.body).to eql 'hello bye'
      end
    end
  end

  describe '.insert' do
    it 'inserts middleware in a specific location in the stack' do
      m = Class.new(Grape::Middleware::Base) do
        def call(env)
          env['phony.args'] ||= []
          env['phony.args'] << @options[:message]
          @app.call(env)
        end
      end

      subject.use ApiSpec::PhonyMiddleware, 'bye'
      subject.insert 0, m, message: 'good'
      subject.insert 0, m, message: 'hello'
      subject.get '/' do
        env['phony.args'].join(' ')
      end

      get '/'
      expect(last_response.body).to eql 'hello good bye'
    end
  end

  describe '.http_basic' do
    it 'protects any resources on the same scope' do
      subject.http_basic do |u, _p|
        u == 'allow'
      end
      subject.get(:hello) { 'Hello, world.' }
      get '/hello'
      expect(last_response.status).to eql 401
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response.status).to eql 200
    end

    it 'is scopable' do
      subject.get(:hello) { 'Hello, world.' }
      subject.namespace :admin do
        http_basic do |u, _p|
          u == 'allow'
        end

        get(:hello) { 'Hello, world.' }
      end

      get '/hello'
      expect(last_response.status).to eql 200
      get '/admin/hello'
      expect(last_response.status).to eql 401
    end

    it 'is callable via .auth as well' do
      subject.auth :http_basic do |u, _p|
        u == 'allow'
      end

      subject.get(:hello) { 'Hello, world.' }
      get '/hello'
      expect(last_response.status).to eql 401
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response.status).to eql 200
    end

    it 'has access to the current endpoint' do
      basic_auth_context = nil

      subject.http_basic do |u, _p|
        basic_auth_context = self

        u == 'allow'
      end

      subject.get(:hello) { 'Hello, world.' }
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(basic_auth_context).to be_a_kind_of(Grape::Endpoint)
    end

    it 'has access to helper methods' do
      subject.helpers do
        def authorize(u, p)
          u == 'allow' && p == 'whatever'
        end
      end

      subject.http_basic do |u, p|
        authorize(u, p)
      end

      subject.get(:hello) { 'Hello, world.' }
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response.status).to eql 200
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('disallow', 'whatever')
      expect(last_response.status).to eql 401
    end

    it 'can set instance variables accessible to routes' do
      subject.http_basic do |u, _p|
        @hello = 'Hello, world.'

        u == 'allow'
      end

      subject.get(:hello) { @hello }
      get '/hello', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('allow', 'whatever')
      expect(last_response.status).to eql 200
      expect(last_response.body).to eql 'Hello, world.'
    end
  end

  describe '.logger' do
    subject do
      Class.new(Grape::API) do
        def self.io
          @io ||= StringIO.new
        end
        logger ::Logger.new(io)
      end
    end

    it 'returns an instance of Logger class by default' do
      expect(subject.logger.class).to eql Logger
    end

    it 'allows setting a custom logger' do
      mylogger = Class.new
      subject.logger mylogger
      expect(mylogger).to receive(:info).exactly(1).times
      subject.logger.info 'this will be logged'
    end

    it 'defaults to a standard logger log format' do
      t = Time.at(100)
      allow(Time).to receive(:now).and_return(t)
      message = "this will be logged\n"
      message = "I, [#{Logger::Formatter.new.send(:format_datetime, t)}\##{Process.pid}]  INFO -- : #{message}" if !defined?(Rails) || Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('4.0')
      expect(subject.io).to receive(:write).with(message)
      subject.logger.info 'this will be logged'
    end
  end

  describe '.helpers' do
    it 'is accessible from the endpoint' do
      subject.helpers do
        def hello
          'Hello, world.'
        end
      end

      subject.get '/howdy' do
        hello
      end

      get '/howdy'
      expect(last_response.body).to eql 'Hello, world.'
    end

    it 'is scopable' do
      subject.helpers do
        def generic
          'always there'
        end
      end

      subject.namespace :admin do
        helpers do
          def secret
            'only in admin'
          end
        end

        get '/secret' do
          [generic, secret].join ':'
        end
      end

      subject.get '/generic' do
        [generic, respond_to?(:secret)].join ':'
      end

      get '/generic'
      expect(last_response.body).to eql 'always there:false'
      get '/admin/secret'
      expect(last_response.body).to eql 'always there:only in admin'
    end

    it 'is reopenable' do
      subject.helpers do
        def one
          1
        end
      end

      subject.helpers do
        def two
          2
        end
      end

      subject.get 'howdy' do
        [one, two]
      end

      expect { get '/howdy' }.not_to raise_error
    end

    it 'allows for modules' do
      mod = Module.new do
        def hello
          'Hello, world.'
        end
      end
      subject.helpers mod

      subject.get '/howdy' do
        hello
      end

      get '/howdy'
      expect(last_response.body).to eql 'Hello, world.'
    end

    it 'allows multiple calls with modules and blocks' do
      subject.helpers Module.new do
        def one
          1
        end
      end
      subject.helpers Module.new do
        def two
          2
        end
      end
      subject.helpers do
        def three
          3
        end
      end
      subject.get 'howdy' do
        [one, two, three]
      end
      expect { get '/howdy' }.not_to raise_error
    end
  end

  describe '.scope' do
    # TODO: refactor this to not be tied to versioning. How about a generic
    # .setting macro?
    it 'scopes the various settings' do
      subject.prefix 'new'

      subject.scope :legacy do
        prefix 'legacy'
        get '/abc' do
          'abc'
        end
      end

      subject.get '/def' do
        'def'
      end

      get '/new/abc'
      expect(last_response.status).to eql 404
      get '/legacy/abc'
      expect(last_response.status).to eql 200
      get '/legacy/def'
      expect(last_response.status).to eql 404
      get '/new/def'
      expect(last_response.status).to eql 200
    end
  end

  describe 'lifecycle' do
    let!(:lifecycle) { [] }
    let!(:standard_cycle) do
      %i[before before_validation after_validation api_call after finally]
    end

    let!(:validation_error) do
      %i[before before_validation finally]
    end

    let!(:errored_cycle) do
      %i[before before_validation after_validation api_call finally]
    end

    before do
      current_cycle = lifecycle

      subject.before do
        current_cycle << :before
      end

      subject.before_validation do
        current_cycle << :before_validation
      end

      subject.after_validation do
        current_cycle << :after_validation
      end

      subject.after do
        current_cycle << :after
      end

      subject.finally do
        current_cycle << :finally
      end
    end

    context 'when the api_call succeeds' do
      before do
        current_cycle = lifecycle

        subject.get 'api_call' do
          current_cycle << :api_call
        end
      end

      it 'follows the standard life_cycle' do
        get '/api_call'
        expect(lifecycle).to eq standard_cycle
      end
    end

    context 'when the api_call has a controlled error' do
      before do
        current_cycle = lifecycle

        subject.get 'api_call' do
          current_cycle << :api_call
          error!(:some_error)
        end
      end

      it 'follows the errored life_cycle (skips after)' do
        get '/api_call'
        expect(lifecycle).to eq errored_cycle
      end
    end

    context 'when the api_call has an exception' do
      before do
        current_cycle = lifecycle

        subject.get 'api_call' do
          current_cycle << :api_call
          raise StandardError
        end
      end

      it 'follows the errored life_cycle (skips after)' do
        expect { get '/api_call' }.to raise_error(StandardError)
        expect(lifecycle).to eq errored_cycle
      end
    end

    context 'when the api_call fails validation' do
      before do
        current_cycle = lifecycle

        subject.params do
          requires :some_param, type: String
        end

        subject.get 'api_call' do
          current_cycle << :api_call
        end
      end

      it 'follows the failed_validation cycle (skips after_validation, api_call & after)' do
        get '/api_call'
        expect(lifecycle).to eq validation_error
      end
    end
  end

  describe '.finally' do
    let!(:code) { { has_executed: false } }
    let(:block_to_run) do
      code_to_execute = code
      proc do
        code_to_execute[:has_executed] = true
      end
    end

    context 'when the ensure block has no exceptions' do
      before { subject.finally(&block_to_run) }

      context 'when no API call is made' do
        it 'has not executed the ensure code' do
          expect(code[:has_executed]).to be false
        end
      end

      context 'when no errors occurs' do
        before do
          subject.get '/no_exceptions' do
            'success'
          end
        end

        it 'executes the ensure code' do
          get '/no_exceptions'
          expect(last_response.body).to eq 'success'
          expect(code[:has_executed]).to be true
        end

        context 'with a helper' do
          let(:block_to_run) do
            code_to_execute = code
            proc do
              code_to_execute[:value] = some_helper
            end
          end

          before do
            subject.helpers do
              def some_helper
                'some_value'
              end
            end

            subject.get '/with_helpers' do
              'success'
            end
          end

          it 'has access to the helper' do
            get '/with_helpers'
            expect(code[:value]).to eq 'some_value'
          end
        end
      end

      context 'when an unhandled occurs inside the API call' do
        before do
          subject.get '/unhandled_exception' do
            raise StandardError
          end
        end

        it 'executes the ensure code' do
          expect { get '/unhandled_exception' }.to raise_error StandardError
          expect(code[:has_executed]).to be true
        end
      end

      context 'when a handled error occurs inside the API call' do
        before do
          subject.rescue_from(StandardError) { error! 'handled' }
          subject.get '/handled_exception' do
            raise StandardError
          end
        end

        it 'executes the ensure code' do
          get '/handled_exception'
          expect(code[:has_executed]).to be true
          expect(last_response.body).to eq 'handled'
        end
      end
    end
  end

  describe '.rescue_from' do
    it 'does not rescue errors when rescue_from is not set' do
      subject.get '/exception' do
        raise 'rain!'
      end
      expect { get '/exception' }.to raise_error(RuntimeError, 'rain!')
    end

    it 'uses custom helpers defined by using #helpers method' do
      subject.helpers do
        def custom_error!(name)
          error! "hello #{name}"
        end
      end
      subject.rescue_from(ArgumentError) { custom_error! :bob }
      subject.get '/custom_error' do
        raise ArgumentError
      end
      get '/custom_error'
      expect(last_response.body).to eq 'hello bob'
    end

    context 'with multiple apis' do
      let(:a) { Class.new(Grape::API) }
      let(:b) { Class.new(Grape::API) }

      before do
        a.helpers do
          def foo
            error!('foo', 401)
          end
        end
        a.rescue_from(:all) { foo }
        a.get { raise 'boo' }
        b.helpers do
          def foo
            error!('bar', 401)
          end
        end
        b.rescue_from(:all) { foo }
        b.get { raise 'boo' }
      end

      it 'avoids polluting global namespace' do
        env = Rack::MockRequest.env_for('/')

        expect(read_chunks(a.call(env)[2])).to eq(['foo'])
        expect(read_chunks(b.call(env)[2])).to eq(['bar'])
        expect(read_chunks(a.call(env)[2])).to eq(['foo'])
      end
    end

    it 'rescues all errors if rescue_from :all is called' do
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.status).to eql 500
      expect(last_response.body).to eq 'rain!'
    end

    it 'rescues all errors with a json formatter' do
      subject.format :json
      subject.default_format :json
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.status).to eql 500
      expect(last_response.body).to eq({ error: 'rain!' }.to_json)
    end

    it 'rescues only certain errors if rescue_from is called with specific errors' do
      subject.rescue_from ArgumentError
      subject.get('/rescued') { raise ArgumentError }
      subject.get('/unrescued') { raise 'beefcake' }

      get '/rescued'
      expect(last_response.status).to eql 500

      expect { get '/unrescued' }.to raise_error(RuntimeError, 'beefcake')
    end

    it 'mimics default ruby "rescue" handler' do
      # The exception is matched to the rescue starting at the top, and matches only once

      subject.rescue_from ArgumentError do |e|
        error!(e, 402)
      end
      subject.rescue_from StandardError do |e|
        error!(e, 401)
      end

      subject.get('/child_of_standard_error') { raise ArgumentError }
      subject.get('/standard_error') { raise StandardError }

      get '/child_of_standard_error'
      expect(last_response.status).to eql 402

      get '/standard_error'
      expect(last_response.status).to eql 401
    end

    context 'CustomError subclass of Grape::Exceptions::Base' do
      before do
        module ApiSpec
          class CustomError < Grape::Exceptions::Base; end
        end
      end

      it 'does not re-raise exceptions of type Grape::Exceptions::Base' do
        subject.get('/custom_exception') { raise ApiSpec::CustomError }

        expect { get '/custom_exception' }.not_to raise_error
      end

      it 'rescues custom grape exceptions' do
        subject.rescue_from ApiSpec::CustomError do |e|
          rack_response('New Error', e.status)
        end
        subject.get '/custom_error' do
          raise ApiSpec::CustomError.new(status: 400, message: 'Custom Error')
        end

        get '/custom_error'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('New Error')
      end
    end

    it 'can rescue exceptions raised in the formatter' do
      formatter = double(:formatter)
      allow(formatter).to receive(:call) { raise StandardError }
      allow(Grape::Formatter).to receive(:formatter_for) { formatter }

      subject.rescue_from :all do |_e|
        rack_response('Formatter Error', 500)
      end
      subject.get('/formatter_exception') { 'Hello world' }

      get '/formatter_exception'
      expect(last_response.status).to eql 500
      expect(last_response.body).to eq('Formatter Error')
    end

    it 'uses default_rescue_handler to handle invalid response from rescue_from' do
      subject.rescue_from(:all) { 'error' }
      subject.get('/') { raise }

      expect_any_instance_of(Grape::Middleware::Error).to receive(:default_rescue_handler).and_call_original
      get '/'
      expect(last_response.status).to eql 500
      expect(last_response.body).to eql 'Invalid response'
    end
  end

  describe '.rescue_from klass, block' do
    it 'rescues Exception' do
      subject.rescue_from RuntimeError do |e|
        rack_response("rescued from #{e.message}", 202)
      end
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.status).to eql 202
      expect(last_response.body).to eq('rescued from rain!')
    end

    context 'custom errors' do
      before do
        class ConnectionError < RuntimeError; end
        class DatabaseError < RuntimeError; end
        class CommunicationError < StandardError; end
      end

      it 'rescues an error via rescue_from :all' do
        subject.rescue_from :all do |e|
          rack_response("rescued from #{e.class.name}", 500)
        end
        subject.get '/exception' do
          raise ConnectionError
        end
        get '/exception'
        expect(last_response.status).to eql 500
        expect(last_response.body).to eq('rescued from ConnectionError')
      end
      it 'rescues a specific error' do
        subject.rescue_from ConnectionError do |e|
          rack_response("rescued from #{e.class.name}", 500)
        end
        subject.get '/exception' do
          raise ConnectionError
        end
        get '/exception'
        expect(last_response.status).to eql 500
        expect(last_response.body).to eq('rescued from ConnectionError')
      end
      it 'rescues a subclass of an error by default' do
        subject.rescue_from RuntimeError do |e|
          rack_response("rescued from #{e.class.name}", 500)
        end
        subject.get '/exception' do
          raise ConnectionError
        end
        get '/exception'
        expect(last_response.status).to eql 500
        expect(last_response.body).to eq('rescued from ConnectionError')
      end
      it 'rescues multiple specific errors' do
        subject.rescue_from ConnectionError do |e|
          rack_response("rescued from #{e.class.name}", 500)
        end
        subject.rescue_from DatabaseError do |e|
          rack_response("rescued from #{e.class.name}", 500)
        end
        subject.get '/connection' do
          raise ConnectionError
        end
        subject.get '/database' do
          raise DatabaseError
        end
        get '/connection'
        expect(last_response.status).to eql 500
        expect(last_response.body).to eq('rescued from ConnectionError')
        get '/database'
        expect(last_response.status).to eql 500
        expect(last_response.body).to eq('rescued from DatabaseError')
      end
      it 'does not rescue a different error' do
        subject.rescue_from RuntimeError do |e|
          rack_response("rescued from #{e.class.name}", 500)
        end
        subject.get '/uncaught' do
          raise CommunicationError
        end
        expect { get '/uncaught' }.to raise_error(CommunicationError)
      end
    end
  end

  describe '.rescue_from klass, lambda' do
    it 'rescues an error with the lambda' do
      subject.rescue_from ArgumentError, lambda {
        rack_response('rescued with a lambda', 400)
      }
      subject.get('/rescue_lambda') { raise ArgumentError }

      get '/rescue_lambda'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('rescued with a lambda')
    end

    it 'can execute the lambda with an argument' do
      subject.rescue_from ArgumentError, lambda { |e|
        rack_response(e.message, 400)
      }
      subject.get('/rescue_lambda') { raise ArgumentError, 'lambda takes an argument' }

      get '/rescue_lambda'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('lambda takes an argument')
    end
  end

  describe '.rescue_from klass, with: :method_name' do
    it 'rescues an error with the specified method name' do
      subject.helpers do
        def rescue_arg_error
          error!('500 ArgumentError', 500)
        end

        def rescue_no_method_error
          error!('500 NoMethodError', 500)
        end
      end
      subject.rescue_from ArgumentError, with: :rescue_arg_error
      subject.rescue_from NoMethodError, with: :rescue_no_method_error
      subject.get('/rescue_arg_error') { raise ArgumentError }
      subject.get('/rescue_no_method_error') { raise NoMethodError }

      get '/rescue_arg_error'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('500 ArgumentError')

      get '/rescue_no_method_error'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('500 NoMethodError')
    end

    it 'aborts if the specified method name does not exist' do
      subject.rescue_from :all, with: :not_exist_method
      subject.get('/rescue_method') { raise StandardError }

      expect { get '/rescue_method' }.to raise_error(NoMethodError, 'undefined method `not_exist_method\'')
    end

    it 'correctly chooses exception handler if :all handler is specified' do
      subject.helpers do
        def rescue_arg_error
          error!('500 ArgumentError', 500)
        end

        def rescue_all_errors
          error!('500 AnotherError', 500)
        end
      end

      subject.rescue_from ArgumentError, with: :rescue_arg_error
      subject.rescue_from :all, with: :rescue_all_errors
      subject.get('/argument_error') { raise ArgumentError }
      subject.get('/another_error') { raise NoMethodError }

      get '/argument_error'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('500 ArgumentError')

      get '/another_error'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('500 AnotherError')
    end
  end

  describe '.rescue_from klass, rescue_subclasses: boolean' do
    before do
      module ApiSpec
        module APIErrors
          class ParentError < StandardError; end
          class ChildError < ParentError; end
        end
      end
    end

    it 'rescues error as well as subclass errors with rescue_subclasses option set' do
      subject.rescue_from ApiSpec::APIErrors::ParentError, rescue_subclasses: true do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/caught_child' do
        raise ApiSpec::APIErrors::ChildError
      end
      subject.get '/caught_parent' do
        raise ApiSpec::APIErrors::ParentError
      end
      subject.get '/uncaught_parent' do
        raise StandardError
      end

      get '/caught_child'
      expect(last_response.status).to eql 500
      get '/caught_parent'
      expect(last_response.status).to eql 500
      expect { get '/uncaught_parent' }.to raise_error(StandardError)
    end

    it 'sets rescue_subclasses to true by default' do
      subject.rescue_from ApiSpec::APIErrors::ParentError do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/caught_child' do
        raise ApiSpec::APIErrors::ChildError
      end

      get '/caught_child'
      expect(last_response.status).to eql 500
    end

    it 'does not rescue child errors if rescue_subclasses is false' do
      subject.rescue_from ApiSpec::APIErrors::ParentError, rescue_subclasses: false do |e|
        rack_response("rescued from #{e.class.name}", 500)
      end
      subject.get '/uncaught' do
        raise ApiSpec::APIErrors::ChildError
      end
      expect { get '/uncaught' }.to raise_error(ApiSpec::APIErrors::ChildError)
    end
  end

  describe '.rescue_from :grape_exceptions' do
    before do
      subject.rescue_from :grape_exceptions
    end

    let(:grape_exception) do
      Grape::Exceptions::Base.new(status: 400, message: 'Grape Error')
    end

    it 'rescues grape exceptions' do
      exception = grape_exception
      subject.get('/grape_exception') { raise exception }

      get '/grape_exception'

      expect(last_response.status).to eq(exception.status)
      expect(last_response.body).to eq(exception.message)
    end

    it 'rescues grape exceptions with a user-defined handler' do
      subject.rescue_from grape_exception.class do |_error|
        rack_response('Redefined Error', 403)
      end

      exception = grape_exception
      subject.get('/grape_exception') { raise exception }

      get '/grape_exception'

      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq('Redefined Error')
    end
  end

  describe '.error_format' do
    it 'rescues all errors and return :txt' do
      subject.rescue_from :all
      subject.format :txt
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.body).to eql 'rain!'
    end

    it 'rescues all errors and return :txt with backtrace' do
      subject.rescue_from :all, backtrace: true
      subject.format :txt
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.body.start_with?("rain!\r\n")).to be true
    end

    it 'rescues all errors with a default formatter' do
      subject.default_format :foo
      subject.content_type :foo, 'text/foo'
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception.foo'
      expect(last_response.body).to start_with 'rain!'
    end

    it 'defaults the error formatter to format' do
      subject.format :json
      subject.rescue_from :all
      subject.content_type :json, 'application/json'
      subject.content_type :foo, 'text/foo'
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception.json'
      expect(last_response.body).to eq('{"error":"rain!"}')
      get '/exception.foo'
      expect(last_response.body).to eq('{"error":"rain!"}')
    end

    context 'class' do
      before :each do
        module ApiSpec
          class CustomErrorFormatter
            def self.call(message, _backtrace, _options, _env, _original_exception)
              "message: #{message} @backtrace"
            end
          end
        end
      end
      it 'returns a custom error format' do
        subject.rescue_from :all, backtrace: true
        subject.error_formatter :txt, ApiSpec::CustomErrorFormatter
        subject.get '/exception' do
          raise 'rain!'
        end
        get '/exception'
        expect(last_response.body).to eq('message: rain! @backtrace')
      end
    end

    describe 'with' do
      context 'class' do
        before :each do
          module ApiSpec
            class CustomErrorFormatter
              def self.call(message, _backtrace, _option, _env, _original_exception)
                "message: #{message} @backtrace"
              end
            end
          end
        end

        it 'returns a custom error format' do
          subject.rescue_from :all, backtrace: true
          subject.error_formatter :txt, with: ApiSpec::CustomErrorFormatter
          subject.get('/exception') { raise 'rain!' }

          get '/exception'
          expect(last_response.body).to eq('message: rain! @backtrace')
        end
      end
    end

    it 'rescues all errors and return :json' do
      subject.rescue_from :all
      subject.format :json
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.body).to eql '{"error":"rain!"}'
    end
    it 'rescues all errors and return :json with backtrace' do
      subject.rescue_from :all, backtrace: true
      subject.format :json
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      json = ::Grape::Json.load(last_response.body)
      expect(json['error']).to eql 'rain!'
      expect(json['backtrace'].length).to be > 0
    end
    it 'rescues error! and return txt' do
      subject.format :txt
      subject.get '/error' do
        error!('Access Denied', 401)
      end
      get '/error'
      expect(last_response.body).to eql 'Access Denied'
    end
    context 'with json format' do
      before { subject.format :json }

      it 'rescues error! called with a string and returns json' do
        subject.get('/error') { error!(:failure, 401) }
      end
      it 'rescues error! called with a symbol and returns json' do
        subject.get('/error') { error!(:failure, 401) }
      end
      it 'rescues error! called with a hash and returns json' do
        subject.get('/error') { error!({ error: :failure }, 401) }
      end

      after do
        get '/error'
        expect(last_response.body).to eql('{"error":"failure"}')
      end
    end
  end

  describe '.content_type' do
    it 'sets additional content-type' do
      subject.content_type :xls, 'application/vnd.ms-excel'
      subject.get :excel do
        'some binary content'
      end
      get '/excel.xls'
      expect(last_response.content_type).to eq('application/vnd.ms-excel')
    end
    it 'allows to override content-type' do
      subject.get :content do
        content_type 'text/javascript'
        'var x = 1;'
      end
      get '/content'
      expect(last_response.content_type).to eq('text/javascript')
    end
    it 'removes existing content types' do
      subject.content_type :xls, 'application/vnd.ms-excel'
      subject.get :excel do
        'some binary content'
      end
      get '/excel.json'
      expect(last_response.status).to eq(406)
      if ActiveSupport::VERSION::MAJOR == 3
        expect(last_response.body).to eq('The requested format &#x27;txt&#x27; is not supported.')
      else
        expect(last_response.body).to eq('The requested format &#39;txt&#39; is not supported.')
      end
    end
  end

  describe '.formatter' do
    context 'multiple formatters' do
      before :each do
        subject.formatter :json, ->(object, _env) { "{\"custom_formatter\":\"#{object[:some]}\"}" }
        subject.formatter :txt, ->(object, _env) { "custom_formatter: #{object[:some]}" }
        subject.get :simple do
          { some: 'hash' }
        end
      end
      it 'sets one formatter' do
        get '/simple.json'
        expect(last_response.body).to eql '{"custom_formatter":"hash"}'
      end
      it 'sets another formatter' do
        get '/simple.txt'
        expect(last_response.body).to eql 'custom_formatter: hash'
      end
    end
    context 'custom formatter' do
      before :each do
        subject.content_type :json, 'application/json'
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, ->(object, _env) { "{\"custom_formatter\":\"#{object[:some]}\"}" }
        subject.get :simple do
          { some: 'hash' }
        end
      end
      it 'uses json' do
        get '/simple.json'
        expect(last_response.body).to eql '{"some":"hash"}'
      end
      it 'uses custom formatter' do
        get '/simple.custom', 'HTTP_ACCEPT' => 'application/custom'
        expect(last_response.body).to eql '{"custom_formatter":"hash"}'
      end
    end
    context 'custom formatter class' do
      module ApiSpec
        module CustomFormatter
          def self.call(object, _env)
            "{\"custom_formatter\":\"#{object[:some]}\"}"
          end
        end
      end
      before :each do
        subject.content_type :json, 'application/json'
        subject.content_type :custom, 'application/custom'
        subject.formatter :custom, ApiSpec::CustomFormatter
        subject.get :simple do
          { some: 'hash' }
        end
      end
      it 'uses json' do
        get '/simple.json'
        expect(last_response.body).to eql '{"some":"hash"}'
      end
      it 'uses custom formatter' do
        get '/simple.custom', 'HTTP_ACCEPT' => 'application/custom'
        expect(last_response.body).to eql '{"custom_formatter":"hash"}'
      end
    end
  end

  describe '.parser' do
    it 'parses data in format requested by content-type' do
      subject.format :json
      subject.post '/data' do
        { x: params[:x] }
      end
      post '/data', '{"x":42}', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq('{"x":42}')
    end
    context 'lambda parser' do
      before :each do
        subject.content_type :txt, 'text/plain'
        subject.content_type :custom, 'text/custom'
        subject.parser :custom, ->(object, _env) { { object.to_sym => object.to_s.reverse } }
        subject.put :simple do
          params[:simple]
        end
      end
      ['text/custom', 'text/custom; charset=UTF-8'].each do |content_type|
        it "uses parser for #{content_type}" do
          put '/simple', 'simple', 'CONTENT_TYPE' => content_type
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eql 'elpmis'
        end
      end
    end
    context 'custom parser class' do
      module ApiSpec
        module CustomParser
          def self.call(object, _env)
            { object.to_sym => object.to_s.reverse }
          end
        end
      end
      before :each do
        subject.content_type :txt, 'text/plain'
        subject.content_type :custom, 'text/custom'
        subject.parser :custom, ApiSpec::CustomParser
        subject.put :simple do
          params[:simple]
        end
      end
      it 'uses custom parser' do
        put '/simple', 'simple', 'CONTENT_TYPE' => 'text/custom'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eql 'elpmis'
      end
    end
    if Object.const_defined? :MultiXml
      context 'multi_xml' do
        it "doesn't parse yaml" do
          subject.put :yaml do
            params[:tag]
          end
          put '/yaml', '<tag type="symbol">a123</tag>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.status).to eq(400)
          expect(last_response.body).to eql 'Disallowed type attribute: "symbol"'
        end
      end
    else
      context 'default xml parser' do
        it 'parses symbols' do
          subject.put :yaml do
            params[:tag]
          end
          put '/yaml', '<tag type="symbol">a123</tag>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eql '{"type"=>"symbol", "__content__"=>"a123"}'
        end
      end
    end
    context 'none parser class' do
      before :each do
        subject.parser :json, nil
        subject.put 'data' do
          "body: #{env['api.request.body']}"
        end
      end
      it 'does not parse data' do
        put '/data', 'not valid json', 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('body: not valid json')
      end
    end
  end

  describe '.default_format' do
    before :each do
      subject.format :json
      subject.default_format :json
    end
    it 'returns data in default format' do
      subject.get '/data' do
        { x: 42 }
      end
      get '/data'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('{"x":42}')
    end
    it 'parses data in default format' do
      subject.post '/data' do
        { x: params[:x] }
      end
      post '/data', '{"x":42}', 'CONTENT_TYPE' => ''
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq('{"x":42}')
    end
  end

  describe '.default_error_status' do
    it 'allows setting default_error_status' do
      subject.rescue_from :all
      subject.default_error_status 200
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.status).to eql 200
    end
    it 'has a default error status' do
      subject.rescue_from :all
      subject.get '/exception' do
        raise 'rain!'
      end
      get '/exception'
      expect(last_response.status).to eql 500
    end
    it 'uses the default error status in error!' do
      subject.rescue_from :all
      subject.default_error_status 400
      subject.get '/exception' do
        error! 'rain!'
      end
      get '/exception'
      expect(last_response.status).to eql 400
    end
  end

  context 'http_codes' do
    let(:error_presenter) do
      Class.new(Grape::Entity) do
        expose :code
        expose :static

        def static
          'some static text'
        end
      end
    end

    it 'is used as presenter' do
      subject.desc 'some desc', http_codes: [
        [408, 'Unauthorized', error_presenter]
      ]

      subject.get '/exception' do
        error!({ code: 408 }, 408)
      end

      get '/exception'
      expect(last_response.status).to eql 408
      expect(last_response.body).to eql({ code: 408, static: 'some static text' }.to_json)
    end

    it 'presented with' do
      error = { code: 408, with: error_presenter }.freeze
      subject.get '/exception' do
        error! error, 408
      end

      get '/exception'
      expect(last_response.status).to eql 408
      expect(last_response.body).to eql({ code: 408, static: 'some static text' }.to_json)
    end
  end

  context 'routes' do
    describe 'empty api structure' do
      it 'returns an empty array of routes' do
        expect(subject.routes).to eq([])
      end
    end
    describe 'single method api structure' do
      before(:each) do
        subject.get :ping do
          'pong'
        end
      end
      it 'returns one route' do
        expect(subject.routes.size).to eq(1)
        route = subject.routes[0]
        expect(route.version).to be_nil
        expect(route.path).to eq('/ping(.:format)')
        expect(route.request_method).to eq('GET')
      end
    end
    describe 'api structure with two versions and a namespace' do
      before :each do
        subject.version 'v1', using: :path
        subject.get 'version' do
          api.version
        end
        # version v2
        subject.version 'v2', using: :path
        subject.prefix 'p'
        subject.namespace 'n1' do
          namespace 'n2' do
            get 'version' do
              api.version
            end
          end
        end
      end
      it 'returns the latest version set' do
        expect(subject.version).to eq('v2')
      end
      it 'returns versions' do
        expect(subject.versions).to eq(%w[v1 v2])
      end
      it 'sets route paths' do
        expect(subject.routes.size).to be >= 2
        expect(subject.routes[0].path).to eq('/:version/version(.:format)')
        expect(subject.routes[1].path).to eq('/p/:version/n1/n2/version(.:format)')
      end
      it 'sets route versions' do
        expect(subject.routes[0].version).to eq('v1')
        expect(subject.routes[1].version).to eq('v2')
      end
      it 'sets a nested namespace' do
        expect(subject.routes[1].namespace).to eq('/n1/n2')
      end
      it 'sets prefix' do
        expect(subject.routes[1].prefix).to eq('p')
      end
    end
    describe 'api structure with additional parameters' do
      before(:each) do
        subject.params do
          requires :token, desc: 'a token'
          optional :limit, desc: 'the limit'
        end
        subject.get 'split/:string' do
          params[:string].split(params[:token], (params[:limit] || 0).to_i)
        end
      end
      it 'splits a string' do
        get '/split/a,b,c.json', token: ','
        expect(last_response.body).to eq('["a","b","c"]')
      end
      it 'splits a string with limit' do
        get '/split/a,b,c.json', token: ',', limit: '2'
        expect(last_response.body).to eq('["a","b,c"]')
      end
      it 'sets params' do
        expect(subject.routes.map do |route|
          { params: route.params }
        end).to eq [
          {
            params: {
              'string' => '',
              'token' => { required: true, desc: 'a token' },
              'limit' => { required: false, desc: 'the limit' }
            }
          }
        ]
      end
    end
    describe 'api structure with multiple apis' do
      before(:each) do
        subject.params do
          requires :one, desc: 'a token'
          optional :two, desc: 'the limit'
        end
        subject.get 'one' do
        end

        subject.params do
          requires :three, desc: 'a token'
          optional :four, desc: 'the limit'
        end
        subject.get 'two' do
        end
      end
      it 'sets params' do
        expect(subject.routes.map do |route|
          { params: route.params }
        end).to eq [
          {
            params: {
              'one' => { required: true, desc: 'a token' },
              'two' => { required: false, desc: 'the limit' }
            }
          },
          {
            params: {
              'three' => { required: true, desc: 'a token' },
              'four' => { required: false, desc: 'the limit' }
            }
          }
        ]
      end
    end
    describe 'api structure with an api without params' do
      before(:each) do
        subject.params do
          requires :one, desc: 'a token'
          optional :two, desc: 'the limit'
        end
        subject.get 'one' do
        end

        subject.get 'two' do
        end
      end
      it 'sets params' do
        expect(subject.routes.map do |route|
          { params: route.params }
        end).to eq [
          {
            params: {
              'one' => { required: true, desc: 'a token' },
              'two' => { required: false, desc: 'the limit' }
            }
          },
          {
            params: {}
          }
        ]
      end
    end
    describe 'api with a custom route setting' do
      before(:each) do
        subject.route_setting :custom, key: 'value'
        subject.get 'one'
      end
      it 'exposed' do
        expect(subject.routes.count).to eq 1
        route = subject.routes.first
        expect(route.settings[:custom]).to eq(key: 'value')
      end
    end
    describe 'status' do
      it 'can be set to arbitrary Integer value' do
        subject.get '/foo' do
          status 210
        end
        get '/foo'
        expect(last_response.status).to eq 210
      end
      it 'can be set with a status code symbol' do
        subject.get '/foo' do
          status :see_other
        end
        get '/foo'
        expect(last_response.status).to eq 303
      end
    end
  end

  context 'desc' do
    it 'empty array of routes' do
      expect(subject.routes).to eq([])
    end
    it 'empty array of routes' do
      subject.desc 'grape api'
      expect(subject.routes).to eq([])
    end
    it 'describes a method' do
      subject.desc 'first method'
      subject.get :first
      expect(subject.routes.length).to eq(1)
      route = subject.routes.first
      expect(route.description).to eq('first method')
      expect(route.route_foo).to be_nil
      expect(route.params).to eq({})
      expect(route.options).to be_a_kind_of(Hash)
    end
    it 'has params which does not include format and version as named captures' do
      subject.version :v1, using: :path
      subject.get :first
      param_keys = subject.routes.first.params.keys
      expect(param_keys).not_to include('format')
      expect(param_keys).not_to include('version')
    end
    it 'describes methods separately' do
      subject.desc 'first method'
      subject.get :first
      subject.desc 'second method'
      subject.get :second
      expect(subject.routes.count).to eq(2)
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'first method', params: {} },
        { description: 'second method', params: {} }
      ]
    end
    it 'resets desc' do
      subject.desc 'first method'
      subject.get :first
      subject.get :second
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'first method', params: {} },
        { description: nil, params: {} }
      ]
    end
    it 'namespaces and describe arbitrary parameters' do
      subject.namespace 'ns' do
        desc 'ns second', foo: 'bar'
        get 'second'
      end
      expect(subject.routes.map do |route|
        { description: route.description, foo: route.route_foo, params: route.params }
      end).to eq [
        { description: 'ns second', foo: 'bar', params: {} }
      ]
    end
    it 'includes details' do
      subject.desc 'method', details: 'method details'
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, details: route.details, params: route.params }
      end).to eq [
        { description: 'method', details: 'method details', params: {} }
      ]
    end
    it 'describes a method with parameters' do
      subject.desc 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } }
      subject.get 'reverse' do
        params[:s].reverse
      end
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } } }
      ]
    end
    it 'does not inherit param descriptions in consequent namespaces' do
      subject.desc 'global description'
      subject.params do
        requires :param1
        optional :param2
      end
      subject.namespace 'ns1' do
        get { ; }
      end
      subject.params do
        optional :param2
      end
      subject.namespace 'ns2' do
        get { ; }
      end
      routes_doc = subject.routes.map do |route|
        { description: route.description, params: route.params }
      end
      expect(routes_doc).to eq [
        { description: 'global description',
          params: {
            'param1' => { required: true },
            'param2' => { required: false }
          } },
        { description: 'global description',
          params: {
            'param2' => { required: false }
          } }
      ]
    end
    it 'merges the parameters of the namespace with the parameters of the method' do
      subject.desc 'namespace'
      subject.params do
        requires :ns_param, desc: 'namespace parameter'
      end
      subject.namespace 'ns' do
        desc 'method'
        params do
          optional :method_param, desc: 'method parameter'
        end
        get 'method'
      end

      routes_doc = subject.routes.map do |route|
        { description: route.description, params: route.params }
      end
      expect(routes_doc).to eq [
        { description: 'method',
          params: {
            'ns_param' => { required: true, desc: 'namespace parameter' },
            'method_param' => { required: false, desc: 'method parameter' }
          } }
      ]
    end
    it 'merges the parameters of nested namespaces' do
      subject.desc 'ns1'
      subject.params do
        optional :ns_param, desc: 'ns param 1'
        requires :ns1_param, desc: 'ns1 param'
      end
      subject.namespace 'ns1' do
        desc 'ns2'
        params do
          requires :ns_param, desc: 'ns param 2'
          requires :ns2_param, desc: 'ns2 param'
        end
        namespace 'ns2' do
          desc 'method'
          params do
            optional :method_param, desc: 'method param'
          end
          get 'method'
        end
      end
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'method',
          params: {
            'ns_param' => { required: true, desc: 'ns param 2' },
            'ns1_param' => { required: true, desc: 'ns1 param' },
            'ns2_param' => { required: true, desc: 'ns2 param' },
            'method_param' => { required: false, desc: 'method param' }
          } }
      ]
    end
    it 'groups nested params and prevents overwriting of params with same name in different groups' do
      subject.desc 'method'
      subject.params do
        group :group1, type: Array do
          optional :param1, desc: 'group1 param1 desc'
          requires :param2, desc: 'group1 param2 desc'
        end
        group :group2, type: Array do
          optional :param1, desc: 'group2 param1 desc'
          requires :param2, desc: 'group2 param2 desc'
        end
      end
      subject.get 'method'

      expect(subject.routes.map(&:params)).to eq [{
        'group1'         => { required: true, type: 'Array' },
        'group1[param1]' => { required: false, desc: 'group1 param1 desc' },
        'group1[param2]' => { required: true, desc: 'group1 param2 desc' },
        'group2'         => { required: true, type: 'Array' },
        'group2[param1]' => { required: false, desc: 'group2 param1 desc' },
        'group2[param2]' => { required: true, desc: 'group2 param2 desc' }
      }]
    end
    it 'uses full name of parameters in nested groups' do
      subject.desc 'nesting'
      subject.params do
        requires :root_param, desc: 'root param'
        group :nested, type: Array do
          requires :nested_param, desc: 'nested param'
        end
      end
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'nesting',
          params: {
            'root_param' => { required: true, desc: 'root param' },
            'nested' => { required: true, type: 'Array' },
            'nested[nested_param]' => { required: true, desc: 'nested param' }
          } }
      ]
    end
    it 'allows to set the type attribute on :group element' do
      subject.params do
        group :foo, type: Array do
          optional :bar
        end
      end
    end
    it 'parses parameters when no description is given' do
      subject.params do
        requires :one_param, desc: 'one param'
      end
      subject.get 'method'
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: nil, params: { 'one_param' => { required: true, desc: 'one param' } } }
      ]
    end
    it 'does not symbolize params' do
      subject.desc 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } }
      subject.get 'reverse/:s' do
        params[:s].reverse
      end
      expect(subject.routes.map do |route|
        { description: route.description, params: route.params }
      end).to eq [
        { description: 'Reverses a string.', params: { 's' => { desc: 'string to reverse', type: 'string' } } }
      ]
    end
  end

  describe '.mount' do
    let(:mounted_app) { ->(_env) { [200, {}, ['MOUNTED']] } }

    context 'with a bare rack app' do
      before do
        subject.mount mounted_app => '/mounty'
      end

      it 'makes a bare Rack app available at the endpoint' do
        get '/mounty'
        expect(last_response.body).to eq('MOUNTED')
      end

      it 'anchors the routes, passing all subroutes to it' do
        get '/mounty/awesome'
        expect(last_response.body).to eq('MOUNTED')
      end

      it 'is able to cascade' do
        subject.mount lambda { |env|
          headers = {}
          headers['X-Cascade'] == 'pass' unless env['PATH_INFO'].include?('boo')
          [200, headers, ['Farfegnugen']]
        } => '/'

        get '/boo'
        expect(last_response.body).to eq('Farfegnugen')
        get '/mounty'
        expect(last_response.body).to eq('MOUNTED')
      end
    end

    context 'without a hash' do
      it 'calls through setting the route to "/"' do
        subject.mount mounted_app
        get '/'
        expect(last_response.body).to eq('MOUNTED')
      end
    end

    context 'mounting an API' do
      it 'applies the settings of the mounting api' do
        subject.version 'v1', using: :path

        subject.namespace :cool do
          app = Class.new(Grape::API)
          app.get('/awesome') do
            'yo'
          end

          mount app
        end

        get '/v1/cool/awesome'
        expect(last_response.body).to eq('yo')
      end

      it 'applies the settings to nested mounted apis' do
        subject.version 'v1', using: :path

        subject.namespace :cool do
          inner_app = Class.new(Grape::API)
          inner_app.get('/awesome') do
            'yo'
          end

          app = Class.new(Grape::API)
          app.mount inner_app
          mount app
        end

        get '/v1/cool/awesome'
        expect(last_response.body).to eq('yo')
      end

      context 'when some rescues are defined by mounted' do
        it 'inherits parent rescues' do
          subject.rescue_from :all do |e|
            rack_response("rescued from #{e.message}", 202)
          end

          app = Class.new(Grape::API)

          subject.namespace :mounted do
            app.rescue_from ArgumentError
            app.get('/fail') { raise 'doh!' }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.status).to eql 202
          expect(last_response.body).to eq('rescued from doh!')
        end
        it 'prefers rescues defined by mounted if they rescue similar error class' do
          subject.rescue_from StandardError do
            rack_response('outer rescue')
          end

          app = Class.new(Grape::API)

          subject.namespace :mounted do
            rescue_from StandardError do
              rack_response('inner rescue')
            end
            app.get('/fail') { raise 'doh!' }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.body).to eq('inner rescue')
        end
        it 'prefers rescues defined by mounted even if outer is more specific' do
          subject.rescue_from ArgumentError do
            rack_response('outer rescue')
          end

          app = Class.new(Grape::API)

          subject.namespace :mounted do
            rescue_from StandardError do
              rack_response('inner rescue')
            end
            app.get('/fail') { raise ArgumentError.new }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.body).to eq('inner rescue')
        end
        it 'prefers more specific rescues defined by mounted' do
          subject.rescue_from StandardError do
            rack_response('outer rescue')
          end

          app = Class.new(Grape::API)

          subject.namespace :mounted do
            rescue_from ArgumentError do
              rack_response('inner rescue')
            end
            app.get('/fail') { raise ArgumentError.new }
            mount app
          end

          get '/mounted/fail'
          expect(last_response.body).to eq('inner rescue')
        end
      end

      it 'collects the routes of the mounted api' do
        subject.namespace :cool do
          app = Class.new(Grape::API)
          app.get('/awesome') {}
          app.post('/sauce') {}
          mount app
        end
        expect(subject.routes.size).to eq(2)
        expect(subject.routes.first.path).to match(%r{\/cool\/awesome})
        expect(subject.routes.last.path).to match(%r{\/cool\/sauce})
      end

      it 'mounts on a path' do
        subject.namespace :cool do
          app = Class.new(Grape::API)
          app.get '/awesome' do
            'sauce'
          end
          mount app => '/mounted'
        end
        get '/mounted/cool/awesome'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('sauce')
      end

      it 'mounts on a nested path' do
        APP1 = Class.new(Grape::API)
        APP2 = Class.new(Grape::API)
        APP2.get '/nice' do
          'play'
        end
        # note that the reverse won't work, mount from outside-in
        APP3 = subject
        APP3.mount APP1 => '/app1'
        APP1.mount APP2 => '/app2'
        get '/app1/app2/nice'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('play')
        options '/app1/app2/nice'
        expect(last_response.status).to eq(204)
      end

      it 'responds to options' do
        app = Class.new(Grape::API)
        app.get '/colour' do
          'red'
        end
        app.namespace :pears do
          get '/colour' do
            'green'
          end
        end
        subject.namespace :apples do
          mount app
        end

        get '/apples/colour'
        expect(last_response.status).to eql 200
        expect(last_response.body).to eq('red')
        options '/apples/colour'
        expect(last_response.status).to eql 204
        get '/apples/pears/colour'
        expect(last_response.status).to eql 200
        expect(last_response.body).to eq('green')
        options '/apples/pears/colour'
        expect(last_response.status).to eql 204
      end

      it 'responds to options with path versioning' do
        subject.version 'v1', using: :path
        subject.namespace :apples do
          app = Class.new(Grape::API)
          app.get('/colour') do
            'red'
          end
          mount app
        end

        get '/v1/apples/colour'
        expect(last_response.status).to eql 200
        expect(last_response.body).to eq('red')
        options '/v1/apples/colour'
        expect(last_response.status).to eql 204
      end

      it 'mounts a versioned API with nested resources' do
        api = Class.new(Grape::API) do
          version 'v1'
          resources :users do
            get :hello do
              'hello users'
            end
          end
        end
        subject.mount api

        get '/v1/users/hello'
        expect(last_response.body).to eq('hello users')
      end

      it 'mounts a prefixed API with nested resources' do
        api = Class.new(Grape::API) do
          prefix 'api'
          resources :users do
            get :hello do
              'hello users'
            end
          end
        end
        subject.mount api

        get '/api/users/hello'
        expect(last_response.body).to eq('hello users')
      end

      it 'applies format to a mounted API with nested resources' do
        api = Class.new(Grape::API) do
          format :json
          resources :users do
            get do
              { users: true }
            end
          end
        end
        subject.mount api

        get '/users'
        expect(last_response.body).to eq({ users: true }.to_json)
      end

      it 'applies auth to a mounted API with nested resources' do
        api = Class.new(Grape::API) do
          format :json
          http_basic do |username, password|
            username == 'username' && password == 'password'
          end
          resources :users do
            get do
              { users: true }
            end
          end
        end
        subject.mount api

        get '/users'
        expect(last_response.status).to eq(401)

        get '/users', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('username', 'password')
        expect(last_response.body).to eq({ users: true }.to_json)
      end

      it 'mounts multiple versioned APIs with nested resources' do
        api1 = Class.new(Grape::API) do
          version 'one', using: :header, vendor: 'test'
          resources :users do
            get :hello do
              'one'
            end
          end
        end

        api2 = Class.new(Grape::API) do
          version 'two', using: :header, vendor: 'test'
          resources :users do
            get :hello do
              'two'
            end
          end
        end

        subject.mount api1
        subject.mount api2

        versioned_get '/users/hello', 'one', using: :header, vendor: 'test'
        expect(last_response.body).to eq('one')
        versioned_get '/users/hello', 'two', using: :header, vendor: 'test'
        expect(last_response.body).to eq('two')
      end

      it 'recognizes potential versions with mounted path' do
        a = Class.new(Grape::API) do
          version :v1, using: :path

          get '/hello' do
            'hello'
          end
        end

        b = Class.new(Grape::API) do
          version :v1, using: :path

          get '/world' do
            'world'
          end
        end

        subject.mount a => '/one'
        subject.mount b => '/two'

        get '/one/v1/hello'
        expect(last_response.status).to eq 200

        get '/two/v1/world'
        expect(last_response.status).to eq 200
      end

      context 'when mounting class extends a subclass of Grape::API' do
        it 'mounts APIs with the same superclass' do
          base_api = Class.new(Grape::API)
          a = Class.new(base_api)
          b = Class.new(base_api)

          expect { a.mount b }.to_not raise_error
        end
      end

      context 'when including a module' do
        let(:included_module) do
          Module.new do
            def self.included(base)
              base.extend(ClassMethods)
            end
            module ClassMethods
              def my_method
                @test = true
              end
            end
          end
        end

        it 'should correctly include module in nested mount' do
          module_to_include = included_module
          v1 = Class.new(Grape::API) do
            version :v1, using: :path
            include module_to_include
            my_method
          end
          v2 = Class.new(Grape::API) do
            version :v2, using: :path
          end
          segment_base = Class.new(Grape::API) do
            mount v1
            mount v2
          end

          Class.new(Grape::API) do
            mount segment_base
          end

          expect(v1.my_method).to be_truthy
        end
      end
    end
  end

  describe '.endpoints' do
    it 'adds one for each route created' do
      subject.get '/'
      subject.post '/'
      expect(subject.endpoints.size).to eq(2)
    end
  end

  describe '.compile' do
    it 'sets the instance' do
      expect(subject.instance).to be_nil
      subject.compile
      expect(subject.instance).to be_kind_of(subject.base_instance)
    end
  end

  describe '.change!' do
    it 'invalidates any compiled instance' do
      subject.compile
      subject.change!
      expect(subject.instance).to be_nil
    end
  end

  describe '.endpoint' do
    before(:each) do
      subject.format :json
      subject.get '/endpoint/options' do
        {
          path: options[:path],
          source_location: source.source_location
        }
      end
    end
    it 'path' do
      get '/endpoint/options'
      options = ::Grape::Json.load(last_response.body)
      expect(options['path']).to eq(['/endpoint/options'])
      expect(options['source_location'][0]).to include 'api_spec.rb'
      expect(options['source_location'][1].to_i).to be > 0
    end
  end

  describe '.route' do
    context 'plain' do
      before(:each) do
        subject.get '/' do
          route.path
        end
        subject.get '/path' do
          route.path
        end
      end
      it 'provides access to route info' do
        get '/'
        expect(last_response.body).to eq('/(.:format)')
        get '/path'
        expect(last_response.body).to eq('/path(.:format)')
      end
    end
    context 'with desc' do
      before(:each) do
        subject.desc 'returns description'
        subject.get '/description' do
          route.description
        end
        subject.desc 'returns parameters', params: { 'x' => 'y' }
        subject.get '/params/:id' do
          route.params[params[:id]]
        end
      end
      it 'returns route description' do
        get '/description'
        expect(last_response.body).to eq('returns description')
      end
      it 'returns route parameters' do
        get '/params/x'
        expect(last_response.body).to eq('y')
      end
    end
  end
  describe '.format' do
    context ':txt' do
      before(:each) do
        subject.format :txt
        subject.content_type :json, 'application/json'
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end
      it 'forces txt without an extension' do
        get '/meaning_of_life'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
      it 'does not force txt with an extension' do
        get '/meaning_of_life.json'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_json)
      end
      it 'forces txt from a non-accepting header' do
        get '/meaning_of_life', {}, 'HTTP_ACCEPT' => 'application/json'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
    end
    context ':txt only' do
      before(:each) do
        subject.format :txt
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end
      it 'forces txt without an extension' do
        get '/meaning_of_life'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
      it 'accepts specified extension' do
        get '/meaning_of_life.txt'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
      it 'does not accept extensions other than specified' do
        get '/meaning_of_life.json'
        expect(last_response.status).to eq(404)
      end
      it 'forces txt from a non-accepting header' do
        get '/meaning_of_life', {}, 'HTTP_ACCEPT' => 'application/json'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
    end
    context ':json' do
      before(:each) do
        subject.format :json
        subject.content_type :txt, 'text/plain'
        subject.get '/meaning_of_life' do
          { meaning_of_life: 42 }
        end
      end
      it 'forces json without an extension' do
        get '/meaning_of_life'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_json)
      end
      it 'does not force json with an extension' do
        get '/meaning_of_life.txt'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
      it 'forces json from a non-accepting header' do
        get '/meaning_of_life', {}, 'HTTP_ACCEPT' => 'text/html'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_json)
      end
      it 'can be overwritten with an explicit content type' do
        subject.get '/meaning_of_life_with_content_type' do
          content_type 'text/plain'
          { meaning_of_life: 42 }.to_s
        end
        get '/meaning_of_life_with_content_type'
        expect(last_response.body).to eq({ meaning_of_life: 42 }.to_s)
      end
      it 'raised :error from middleware' do
        middleware = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: 'Unauthorized', status: 42
          end
        end
        subject.use middleware
        subject.get do
        end
        get '/'
        expect(last_response.status).to eq(42)
        expect(last_response.body).to eq({ error: 'Unauthorized' }.to_json)
      end
    end
    context ':serializable_hash' do
      class SerializableHashExample
        def serializable_hash
          { abc: 'def' }
        end
      end

      before(:each) do
        subject.format :serializable_hash
      end
      it 'instance' do
        subject.get '/example' do
          SerializableHashExample.new
        end
        get '/example'
        expect(last_response.body).to eq('{"abc":"def"}')
      end
      it 'root' do
        subject.get '/example' do
          { 'root' => SerializableHashExample.new }
        end
        get '/example'
        expect(last_response.body).to eq('{"root":{"abc":"def"}}')
      end
      it 'array' do
        subject.get '/examples' do
          [SerializableHashExample.new, SerializableHashExample.new]
        end
        get '/examples'
        expect(last_response.body).to eq('[{"abc":"def"},{"abc":"def"}]')
      end
    end
    context ':xml' do
      before(:each) do
        subject.format :xml
      end
      it 'string' do
        subject.get '/example' do
          'example'
        end
        get '/example'
        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<error>
  <message>cannot convert String to xml</message>
</error>
XML
      end
      it 'hash' do
        subject.get '/example' do
          {
            example1: 'example1',
            example2: 'example2'
          }
        end
        get '/example'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <example1>example1</example1>
  <example2>example2</example2>
</hash>
XML
      end
      it 'array' do
        subject.get '/example' do
          %w[example1 example2]
        end
        get '/example'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<strings type="array">
  <string>example1</string>
  <string>example2</string>
</strings>
XML
      end
      it 'raised :error from middleware' do
        middleware = Class.new(Grape::Middleware::Base) do
          def before
            throw :error, message: 'Unauthorized', status: 42
          end
        end
        subject.use middleware
        subject.get do
        end
        get '/'
        expect(last_response.status).to eq(42)
        expect(last_response.body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<error>
  <message>Unauthorized</message>
</error>
XML
      end
    end
  end

  describe '.configure' do
    context 'when given a block' do
      it 'returns self' do
        expect(subject.configure {}).to be subject
      end

      it 'calls the block passing the config' do
        call = [false, nil]
        subject.configure do |config|
          call = [true, config]
        end

        expect(call[0]).to be true
        expect(call[1]).not_to be_nil
      end
    end

    context 'when not given a block' do
      it 'returns a configuration object' do
        expect(subject.configure).to respond_to(:[], :[]=)
      end
    end

    it 'allows configuring the api' do
      subject.configure do |config|
        config[:hello] = 'hello'
        config[:bread] = 'bread'
      end

      subject.get '/hello-bread' do
        "#{configuration[:hello]} #{configuration[:bread]}"
      end

      get '/hello-bread'
      expect(last_response.body).to eq 'hello bread'
    end
  end

  context 'catch-all' do
    before do
      api1 = Class.new(Grape::API)
      api1.version 'v1', using: :path
      api1.get 'hello' do
        'v1'
      end
      api2 = Class.new(Grape::API)
      api2.version 'v2', using: :path
      api2.get 'hello' do
        'v2'
      end
      subject.mount api1
      subject.mount api2
    end
    [true, false].each do |anchor|
      it "anchor=#{anchor}" do
        subject.route :any, '*path', anchor: anchor do
          error!("Unrecognized request path: #{params[:path]} - #{env['PATH_INFO']}#{env['SCRIPT_NAME']}", 404)
        end
        get '/v1/hello'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('v1')
        get '/v2/hello'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('v2')
        options '/v2/hello'
        expect(last_response.status).to eq(204)
        expect(last_response.body).to be_blank
        head '/v2/hello'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to be_blank
        get '/foobar'
        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq('Unrecognized request path: foobar - /foobar')
      end
    end
  end

  context 'cascading' do
    context 'via version' do
      it 'cascades' do
        subject.version 'v1', using: :path, cascade: true
        get '/v1/hello'
        expect(last_response.status).to eq(404)
        expect(last_response.headers['X-Cascade']).to eq('pass')
      end
      it 'does not cascade' do
        subject.version 'v2', using: :path, cascade: false
        get '/v2/hello'
        expect(last_response.status).to eq(404)
        expect(last_response.headers.keys).not_to include 'X-Cascade'
      end
    end
    context 'via endpoint' do
      it 'cascades' do
        subject.cascade true
        get '/hello'
        expect(last_response.status).to eq(404)
        expect(last_response.headers['X-Cascade']).to eq('pass')
      end
      it 'does not cascade' do
        subject.cascade false
        get '/hello'
        expect(last_response.status).to eq(404)
        expect(last_response.headers.keys).not_to include 'X-Cascade'
      end
    end
  end

  context 'with json default_error_formatter' do
    it 'returns json error' do
      subject.content_type :json, 'application/json'
      subject.default_error_formatter :json
      subject.get '/something' do
        'foo'
      end
      get '/something'
      expect(last_response.status).to eq(406)
      if ActiveSupport::VERSION::MAJOR == 3
        expect(last_response.body).to eq('{&quot;error&quot;:&quot;The requested format &#x27;txt&#x27; is not supported.&quot;}')
      else
        expect(last_response.body).to eq('{&quot;error&quot;:&quot;The requested format &#39;txt&#39; is not supported.&quot;}')
      end
    end
  end

  context 'with unsafe HTML format specified' do
    it 'escapes the HTML' do
      subject.content_type :json, 'application/json'
      subject.get '/something' do
        'foo'
      end
      get '/something?format=<script>blah</script>'
      expect(last_response.status).to eq(406)
      if ActiveSupport::VERSION::MAJOR == 3
        expect(last_response.body).to eq('The requested format &#x27;&lt;script&gt;blah&lt;/script&gt;&#x27; is not supported.')
      else
        expect(last_response.body).to eq('The requested format &#39;&lt;script&gt;blah&lt;/script&gt;&#39; is not supported.')
      end
    end
  end

  context 'body' do
    context 'false' do
      before do
        subject.get '/blank' do
          body false
        end
      end
      it 'returns blank body' do
        get '/blank'
        expect(last_response.status).to eq(204)
        expect(last_response.body).to be_blank
      end
    end
    context 'plain text' do
      before do
        subject.get '/text' do
          content_type 'text/plain'
          body 'Hello World'
          'ignored'
        end
      end
      it 'returns blank body' do
        get '/text'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq 'Hello World'
      end
    end
  end

  describe 'normal class methods' do
    subject(:grape_api) { Class.new(Grape::API) }

    before do
      stub_const('MyAPI', grape_api)
    end

    it 'can find the appropiate name' do
      expect(grape_api.name).to eq 'MyAPI'
    end

    it 'is equal to itself' do
      expect(grape_api.itself).to eq grape_api
      expect(grape_api).to eq MyAPI
      expect(grape_api.eql?(MyAPI))
    end
  end

  describe 'const_missing' do
    subject(:grape_api) { Class.new(Grape::API) }
    let(:mounted) do
      Class.new(Grape::API) do
        get '/missing' do
          SomeRandomConstant
        end
      end
    end

    before { subject.mount mounted => '/const' }

    it 'raises an error' do
      expect { get '/const/missing' }.to raise_error(NameError).with_message(/SomeRandomConstant/)
    end
  end
end
