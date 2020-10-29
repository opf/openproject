# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe '.before_each' do
    after { Grape::Endpoint.before_each.clear }

    it 'is settable via block' do
      block = ->(_endpoint) { 'noop' }
      Grape::Endpoint.before_each(&block)
      expect(Grape::Endpoint.before_each.first).to eq(block)
    end

    it 'is settable via reference' do
      block = ->(_endpoint) { 'noop' }
      Grape::Endpoint.before_each block
      expect(Grape::Endpoint.before_each.first).to eq(block)
    end

    it 'is able to override a helper' do
      subject.get('/') { current_user }
      expect { get '/' }.to raise_error(NameError)

      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:current_user).and_return('Bob')
      end

      get '/'
      expect(last_response.body).to eq('Bob')

      Grape::Endpoint.before_each(nil)
      expect { get '/' }.to raise_error(NameError)
    end

    it 'is able to stack helper' do
      subject.get('/') do
        authenticate_user!
        current_user
      end
      expect { get '/' }.to raise_error(NameError)

      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:current_user).and_return('Bob')
      end

      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:authenticate_user!).and_return(true)
      end

      get '/'
      expect(last_response.body).to eq('Bob')

      Grape::Endpoint.before_each(nil)
      expect { get '/' }.to raise_error(NameError)
    end
  end

  describe '#initialize' do
    it 'takes a settings stack, options, and a block' do
      p = proc {}
      expect do
        Grape::Endpoint.new(Grape::Util::InheritableSetting.new, {
                              path: '/',
                              method: :get
                            }, &p)
      end.not_to raise_error
    end
  end

  it 'sets itself in the env upon call' do
    subject.get('/') { 'Hello world.' }
    get '/'
    expect(last_request.env['api.endpoint']).to be_kind_of(Grape::Endpoint)
  end

  describe '#status' do
    it 'is callable from within a block' do
      subject.get('/home') do
        status 206
        'Hello'
      end

      get '/home'
      expect(last_response.status).to eq(206)
      expect(last_response.body).to eq('Hello')
    end

    it 'is set as default to 200 for get' do
      memoized_status = nil
      subject.get('/home') do
        memoized_status = status
        'Hello'
      end

      get '/home'
      expect(last_response.status).to eq(200)
      expect(memoized_status).to eq(200)
      expect(last_response.body).to eq('Hello')
    end

    it 'is set as default to 201 for post' do
      memoized_status = nil
      subject.post('/home') do
        memoized_status = status
        'Hello'
      end

      post '/home'
      expect(last_response.status).to eq(201)
      expect(memoized_status).to eq(201)
      expect(last_response.body).to eq('Hello')
    end
  end

  describe '#header' do
    it 'is callable from within a block' do
      subject.get('/hey') do
        header 'X-Awesome', 'true'
        'Awesome'
      end

      get '/hey'
      expect(last_response.headers['X-Awesome']).to eq('true')
    end
  end

  describe '#headers' do
    before do
      subject.get('/headers') do
        headers.to_json
      end
    end
    it 'includes request headers' do
      get '/headers'
      expect(JSON.parse(last_response.body)).to eq(
        'Host' => 'example.org',
        'Cookie' => ''
      )
    end
    it 'includes additional request headers' do
      get '/headers', nil, 'HTTP_X_GRAPE_CLIENT' => '1'
      expect(JSON.parse(last_response.body)['X-Grape-Client']).to eq('1')
    end
    it 'includes headers passed as symbols' do
      env = Rack::MockRequest.env_for('/headers')
      env['HTTP_SYMBOL_HEADER'.to_sym] = 'Goliath passes symbols'
      body = read_chunks(subject.call(env)[2]).join
      expect(JSON.parse(body)['Symbol-Header']).to eq('Goliath passes symbols')
    end
  end

  describe '#cookies' do
    it 'is callable from within a block' do
      subject.get('/get/cookies') do
        cookies['my-awesome-cookie1'] = 'is cool'
        cookies['my-awesome-cookie2'] = {
          value: 'is cool too',
          domain: 'my.example.com',
          path: '/',
          secure: true
        }
        cookies[:cookie3] = 'symbol'
        cookies['cookie4'] = 'secret code here'
      end

      get('/get/cookies')

      expect(last_response.headers['Set-Cookie'].split("\n").sort).to eql [
        'cookie3=symbol',
        'cookie4=secret+code+here',
        'my-awesome-cookie1=is+cool',
        'my-awesome-cookie2=is+cool+too; domain=my.example.com; path=/; secure'
      ]
    end

    it 'sets browser cookies and does not set response cookies' do
      subject.get('/username') do
        cookies[:username]
      end
      get('/username', {}, 'HTTP_COOKIE' => 'username=mrplum; sandbox=true')

      expect(last_response.body).to eq('mrplum')
      expect(last_response.headers['Set-Cookie']).to be_nil
    end

    it 'sets and update browser cookies' do
      subject.get('/username') do
        cookies[:sandbox] = true if cookies[:sandbox] == 'false'
        cookies[:username] += '_test'
      end
      get('/username', {}, 'HTTP_COOKIE' => 'username=user; sandbox=false')
      expect(last_response.body).to eq('user_test')
      expect(last_response.headers['Set-Cookie']).to match(/username=user_test/)
      expect(last_response.headers['Set-Cookie']).to match(/sandbox=true/)
    end

    it 'deletes cookie' do
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name
        end
        sum
      end
      get '/test', {}, 'HTTP_COOKIE' => 'delete_this_cookie=1; and_this=2'
      expect(last_response.body).to eq('3')
      cookies = Hash[last_response.headers['Set-Cookie'].split("\n").map do |set_cookie|
        cookie = CookieJar::Cookie.from_set_cookie 'http://localhost/test', set_cookie
        [cookie.name, cookie]
      end]
      expect(cookies.size).to eq(2)
      %w[and_this delete_this_cookie].each do |cookie_name|
        cookie = cookies[cookie_name]
        expect(cookie).not_to be_nil
        expect(cookie.value).to eq('deleted')
        expect(cookie.expired?).to be true
      end
    end

    it 'deletes cookies with path' do
      subject.get('/test') do
        sum = 0
        cookies.each do |name, val|
          sum += val.to_i
          cookies.delete name, path: '/test'
        end
        sum
      end
      get('/test', {}, 'HTTP_COOKIE' => 'delete_this_cookie=1; and_this=2')
      expect(last_response.body).to eq('3')
      cookies = Hash[last_response.headers['Set-Cookie'].split("\n").map do |set_cookie|
        cookie = CookieJar::Cookie.from_set_cookie 'http://localhost/test', set_cookie
        [cookie.name, cookie]
      end]
      expect(cookies.size).to eq(2)
      %w[and_this delete_this_cookie].each do |cookie_name|
        cookie = cookies[cookie_name]
        expect(cookie).not_to be_nil
        expect(cookie.value).to eq('deleted')
        expect(cookie.path).to eq('/test')
        expect(cookie.expired?).to be true
      end
    end
  end

  describe '#params' do
    context 'default class' do
      it 'should be a ActiveSupport::HashWithIndifferentAccess' do
        subject.get '/foo' do
          params.class
        end

        get '/foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('ActiveSupport::HashWithIndifferentAccess')
      end
    end

    context 'sets a value to params' do
      it 'params' do
        subject.params do
          requires :a, type: String
        end
        subject.get '/foo' do
          params[:a] = 'bar'
        end

        get '/foo', a: 'foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('bar')
      end
    end
  end

  describe '#declared' do
    before do
      subject.format :json
      subject.params do
        requires :first
        optional :second
        optional :third, default: 'third-default'
        optional :nested, type: Hash do
          optional :fourth
          optional :fifth
          optional :nested_two, type: Hash do
            optional :sixth
            optional :nested_three, type: Hash do
              optional :seventh
            end
          end
          optional :nested_arr, type: Array do
            optional :eighth
          end
        end
        optional :arr, type: Array do
          optional :nineth
        end
      end
    end

    context 'when params are not built with default class' do
      it 'returns an object that corresponds with the params class - hash with indifferent access' do
        subject.params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
        end
        subject.get '/declared' do
          d = declared(params, include_missing: true)
          { declared_class: d.class.to_s }
        end

        get '/declared?first=present'
        expect(JSON.parse(last_response.body)['declared_class']).to eq('ActiveSupport::HashWithIndifferentAccess')
      end

      it 'returns an object that corresponds with the params class - hashie mash' do
        subject.params do
          build_with Grape::Extensions::Hashie::Mash::ParamBuilder
        end
        subject.get '/declared' do
          d = declared(params, include_missing: true)
          { declared_class: d.class.to_s }
        end

        get '/declared?first=present'
        expect(JSON.parse(last_response.body)['declared_class']).to eq('Hashie::Mash')
      end

      it 'returns an object that corresponds with the params class - hash' do
        subject.params do
          build_with Grape::Extensions::Hash::ParamBuilder
        end
        subject.get '/declared' do
          d = declared(params, include_missing: true)
          { declared_class: d.class.to_s }
        end

        get '/declared?first=present'
        expect(JSON.parse(last_response.body)['declared_class']).to eq('Hash')
      end
    end

    it 'should show nil for nested params if include_missing is true' do
      subject.get '/declared' do
        declared(params, include_missing: true)
      end

      get '/declared?first=present'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['nested']['fourth']).to be_nil
    end

    it 'does not work in a before filter' do
      subject.before do
        declared(params)
      end
      subject.get('/declared') { declared(params) }

      expect { get('/declared') }.to raise_error(
        Grape::DSL::InsideRoute::MethodNotYetAvailable
      )
    end

    it 'has as many keys as there are declared params' do
      subject.get '/declared' do
        declared(params)
      end
      get '/declared?first=present'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).keys.size).to eq(5)
    end

    it 'has a optional param with default value all the time' do
      subject.get '/declared' do
        declared(params)
      end
      get '/declared?first=one'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['third']).to eql('third-default')
    end

    it 'builds nested params' do
      subject.get '/declared' do
        declared(params)
      end

      get '/declared?first=present&nested[fourth]=1'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['nested'].keys.size).to eq 4
    end

    it 'builds nested params when given array' do
      subject.get '/dummy' do
      end
      subject.params do
        requires :first
        optional :second
        optional :third, default: 'third-default'
        optional :nested, type: Array do
          optional :fourth
        end
      end
      subject.get '/declared' do
        declared(params)
      end

      get '/declared?first=present&nested[][fourth]=1&nested[][fourth]=2'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['nested'].size).to eq 2
    end

    context 'sets nested objects when the param is missing' do
      it 'to be a hash when include_missing is true' do
        subject.get '/declared' do
          declared(params, include_missing: true)
        end

        get '/declared?first=present'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['nested']).to eq({})
      end

      it 'to be an array when include_missing is true' do
        subject.get '/declared' do
          declared(params, include_missing: true)
        end

        get '/declared?first=present'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['arr']).to be_a(Array)
      end

      it 'to be an array when nested and include_missing is true' do
        subject.get '/declared' do
          declared(params, include_missing: true)
        end

        get '/declared?first=present&nested[fourth]=1'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['nested']['nested_arr']).to be_a(Array)
      end

      it 'to be nil when include_missing is false' do
        subject.get '/declared' do
          declared(params, include_missing: false)
        end

        get '/declared?first=present'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['nested']).to be_nil
      end
    end

    it 'filters out any additional params that are given' do
      subject.get '/declared' do
        declared(params)
      end
      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).key?(:other)).to eq false
    end

    it 'stringifies if that option is passed' do
      subject.get '/declared' do
        declared(params, stringify: true)
      end

      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['first']).to eq 'one'
    end

    it 'does not include missing attributes if that option is passed' do
      subject.get '/declared' do
        error! 'expected nil', 400 if declared(params, include_missing: false).key?(:second)
        ''
      end

      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
    end

    it 'does not include renamed missing attributes if that option is passed' do
      subject.params do
        optional :renamed_original, as: :renamed
      end
      subject.get '/declared' do
        error! 'expected nil', 400 if declared(params, include_missing: false).key?(:renamed)
        ''
      end

      get '/declared?first=one&other=two'
      expect(last_response.status).to eq(200)
    end

    it 'includes attributes with value that evaluates to false' do
      subject.params do
        requires :first
        optional :boolean
      end

      subject.post '/declared' do
        error!('expected false', 400) if declared(params, include_missing: false)[:boolean] != false
        ''
      end

      post '/declared', ::Grape::Json.dump(first: 'one', boolean: false), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'includes attributes with value that evaluates to nil' do
      subject.params do
        requires :first
        optional :second
      end

      subject.post '/declared' do
        error!('expected nil', 400) unless declared(params, include_missing: false)[:second].nil?
        ''
      end

      post '/declared', ::Grape::Json.dump(first: 'one', second: nil), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
    end

    it 'includes missing attributes with defaults when there are nested hashes' do
      subject.get '/dummy' do
      end

      subject.params do
        requires :first
        optional :second
        optional :third, default: nil
        optional :nested, type: Hash do
          optional :fourth, default: nil
          optional :fifth, default: nil
          requires :nested_nested, type: Hash do
            optional :sixth, default: 'sixth-default'
            optional :seven, default: nil
          end
        end
      end

      subject.get '/declared' do
        declared(params, include_missing: false)
      end

      get '/declared?first=present&nested[fourth]=&nested[nested_nested][sixth]=sixth'
      json = JSON.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(json['first']).to eq 'present'
      expect(json['nested'].keys).to eq %w[fourth fifth nested_nested]
      expect(json['nested']['fourth']).to eq ''
      expect(json['nested']['nested_nested'].keys).to eq %w[sixth seven]
      expect(json['nested']['nested_nested']['sixth']).to eq 'sixth'
    end

    it 'does not include missing attributes when there are nested hashes' do
      subject.get '/dummy' do
      end

      subject.params do
        requires :first
        optional :second
        optional :third
        optional :nested, type: Hash do
          optional :fourth
          optional :fifth
        end
      end

      subject.get '/declared' do
        declared(params, include_missing: false)
      end

      get '/declared?first=present&nested[fourth]=4'
      json = JSON.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(json['first']).to eq 'present'
      expect(json['nested'].keys).to eq %w[fourth]
      expect(json['nested']['fourth']).to eq '4'
    end
  end

  describe '#declared; call from child namespace' do
    before do
      subject.format :json
      subject.namespace :parent do
        params do
          requires :parent_name, type: String
        end

        namespace ':parent_name' do
          params do
            requires :child_name, type: String
            requires :child_age, type: Integer
          end

          namespace ':child_name' do
            params do
              requires :grandchild_name, type: String
            end

            get ':grandchild_name' do
              {
                'params' => params,
                'without_parent_namespaces' => declared(params, include_parent_namespaces: false),
                'with_parent_namespaces' => declared(params, include_parent_namespaces: true)
              }
            end
          end
        end
      end

      get '/parent/foo/bar/baz', child_age: 5, extra: 'hello'
    end

    let(:parsed_response) { JSON.parse(last_response.body, symbolize_names: true) }

    it { expect(last_response.status).to eq 200 }

    context 'with include_parent_namespaces: false' do
      it 'returns declared parameters only from current namespace' do
        expect(parsed_response[:without_parent_namespaces]).to eq(
          grandchild_name: 'baz'
        )
      end
    end

    context 'with include_parent_namespaces: true' do
      it 'returns declared parameters from every parent namespace' do
        expect(parsed_response[:with_parent_namespaces]).to eq(
          parent_name: 'foo',
          child_name: 'bar',
          grandchild_name: 'baz',
          child_age: 5
        )
      end
    end

    context 'without declaration' do
      it 'returns all requested parameters' do
        expect(parsed_response[:params]).to eq(
          parent_name: 'foo',
          child_name: 'bar',
          grandchild_name: 'baz',
          child_age: 5,
          extra: 'hello'
        )
      end
    end
  end

  describe '#declared; from a nested mounted endpoint' do
    before do
      doubly_mounted = Class.new(Grape::API)
      doubly_mounted.namespace :more do
        params do
          requires :y, type: Integer
        end
        route_param :y do
          get do
            {
              params: params,
              declared_params: declared(params)
            }
          end
        end
      end

      mounted = Class.new(Grape::API)
      mounted.namespace :another do
        params do
          requires :mount_space, type: Integer
        end
        route_param :mount_space do
          mount doubly_mounted
        end
      end

      subject.format :json
      subject.namespace :something do
        params do
          requires :id, type: Integer
        end
        resource ':id' do
          mount mounted
        end
      end
    end

    it 'can access parent attributes' do
      get '/something/123/another/456/more/789'
      expect(last_response.status).to eq 200
      json = JSON.parse(last_response.body, symbolize_names: true)

      # test all three levels of params
      expect(json[:declared_params][:y]).to eq 789
      expect(json[:declared_params][:mount_space]).to eq 456
      expect(json[:declared_params][:id]).to eq 123
    end
  end

  describe '#declared; mixed nesting' do
    before do
      subject.format :json
      subject.resource :users do
        route_param :id, type: Integer, desc: 'ID desc' do
          # Adding this causes route_setting(:declared_params) to be nil for the
          # get block in namespace 'foo' below
          get do
          end

          namespace 'foo' do
            get do
              {
                params: params,
                declared_params: declared(params),
                declared_params_no_parent: declared(params, include_parent_namespaces: false)
              }
            end
          end
        end
      end
    end

    it 'can access parent route_param' do
      get '/users/123/foo', bar: 'bar'
      expect(last_response.status).to eq 200
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json[:declared_params][:id]).to eq 123
      expect(json[:declared_params_no_parent][:id]).to eq nil
    end
  end

  describe '#declared; with multiple route_param' do
    before do
      mounted = Class.new(Grape::API)
      mounted.namespace :albums do
        get do
          declared(params)
        end
      end

      subject.format :json
      subject.namespace :artists do
        route_param :id, type: Integer do
          get do
            declared(params)
          end

          params do
            requires :filter, type: String
          end
          get :some_route do
            declared(params)
          end
        end

        route_param :artist_id, type: Integer do
          namespace :compositions do
            get do
              declared(params)
            end
          end
        end

        route_param :compositor_id, type: Integer do
          mount mounted
        end
      end
    end

    it 'return only :id without :artist_id' do
      get '/artists/1'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json.key?(:id)).to be_truthy
      expect(json.key?(:artist_id)).not_to be_truthy
    end

    it 'return only :artist_id without :id' do
      get '/artists/1/compositions'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json.key?(:artist_id)).to be_truthy
      expect(json.key?(:id)).not_to be_truthy
    end

    it 'return :filter and :id parameters in declared for second enpoint inside route_param' do
      get '/artists/1/some_route', filter: 'some_filter'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json.key?(:filter)).to be_truthy
      expect(json.key?(:id)).to be_truthy
      expect(json.key?(:artist_id)).not_to be_truthy
    end

    it 'return :compositor_id for mounter in route_param' do
      get '/artists/1/albums'
      json = JSON.parse(last_response.body, symbolize_names: true)

      expect(json.key?(:compositor_id)).to be_truthy
      expect(json.key?(:id)).not_to be_truthy
      expect(json.key?(:artist_id)).not_to be_truthy
    end
  end

  describe '#params' do
    it 'is available to the caller' do
      subject.get('/hey') do
        params[:howdy]
      end

      get '/hey?howdy=hey'
      expect(last_response.body).to eq('hey')
    end

    it 'parses from path segments' do
      subject.get('/hey/:id') do
        params[:id]
      end

      get '/hey/12'
      expect(last_response.body).to eq('12')
    end

    it 'deeply converts nested params' do
      subject.get '/location' do
        params[:location][:city]
      end
      get '/location?location[city]=Dallas'
      expect(last_response.body).to eq('Dallas')
    end

    context 'with special requirements' do
      it 'parses email param with provided requirements for params' do
        subject.get('/:person_email', requirements: { person_email: /.*/ }) do
          params[:person_email]
        end

        get '/someone@example.com'
        expect(last_response.body).to eq('someone@example.com')

        get 'someone@example.com.pl'
        expect(last_response.body).to eq('someone@example.com.pl')
      end

      it 'parses many params with provided regexps' do
        subject.get('/:person_email/test/:number', requirements: { person_email: /someone@(.*).com/, number: /[0-9]/ }) do
          params[:person_email] << params[:number]
        end

        get '/someone@example.com/test/1'
        expect(last_response.body).to eq('someone@example.com1')

        get '/someone@testing.wrong/test/1'
        expect(last_response.status).to eq(404)

        get 'someone@test.com/test/wrong_number'
        expect(last_response.status).to eq(404)

        get 'someone@test.com/wrong_middle/1'
        expect(last_response.status).to eq(404)
      end

      context 'namespace requirements' do
        before :each do
          subject.namespace :outer, requirements: { person_email: /abc@(.*).com/ } do
            get('/:person_email') do
              params[:person_email]
            end

            namespace :inner, requirements: { number: /[0-9]/, person_email: /someone@(.*).com/ } do
              get '/:person_email/test/:number' do
                params[:person_email] << params[:number]
              end
            end
          end
        end

        it 'parse email param with provided requirements for params' do
          get '/outer/abc@example.com'
          expect(last_response.body).to eq('abc@example.com')
        end

        it "should override outer namespace's requirements" do
          get '/outer/inner/someone@testing.wrong/test/1'
          expect(last_response.status).to eq(404)

          get '/outer/inner/someone@testing.com/test/1'
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('someone@testing.com1')
        end
      end
    end

    context 'from body parameters' do
      before(:each) do
        subject.post '/request_body' do
          params[:user]
        end
        subject.put '/request_body' do
          params[:user]
        end
      end

      it 'converts JSON bodies to params' do
        post '/request_body', ::Grape::Json.dump(user: 'Bobby T.'), 'CONTENT_TYPE' => 'application/json'
        expect(last_response.body).to eq('Bobby T.')
      end

      it 'does not convert empty JSON bodies to params' do
        put '/request_body', '', 'CONTENT_TYPE' => 'application/json'
        expect(last_response.body).to eq('')
      end

      if Object.const_defined? :MultiXml
        it 'converts XML bodies to params' do
          post '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq('Bobby T.')
        end

        it 'converts XML bodies to params' do
          put '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq('Bobby T.')
        end
      else
        it 'converts XML bodies to params' do
          post '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq('{"__content__"=>"Bobby T."}')
        end

        it 'converts XML bodies to params' do
          put '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
          expect(last_response.body).to eq('{"__content__"=>"Bobby T."}')
        end
      end

      it 'does not include parameters not defined by the body' do
        subject.post '/omitted_params' do
          error! 400, 'expected nil' if params[:version]
          params[:user]
        end
        post '/omitted_params', ::Grape::Json.dump(user: 'Bob'), 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('Bob')
      end
    end

    it 'responds with a 415 for an unsupported content-type' do
      subject.format :json
      # subject.content_type :json, "application/json"
      subject.put '/request_body' do
        params[:user]
      end
      put '/request_body', '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml'
      expect(last_response.status).to eq(415)
      expect(last_response.body).to eq('{"error":"The provided content-type \'application/xml\' is not supported."}')
    end

    it 'does not accept text/plain in JSON format if application/json is specified as content type' do
      subject.format :json
      subject.default_format :json
      subject.put '/request_body' do
        params[:user]
      end
      put '/request_body', ::Grape::Json.dump(user: 'Bob'), 'CONTENT_TYPE' => 'text/plain'

      expect(last_response.status).to eq(415)
      expect(last_response.body).to eq('{"error":"The provided content-type \'text/plain\' is not supported."}')
    end

    context 'content type with params' do
      before do
        subject.format :json
        subject.content_type :json, 'application/json; charset=utf-8'

        subject.post do
          params[:data]
        end
        post '/', ::Grape::Json.dump(data: { some: 'payload' }), 'CONTENT_TYPE' => 'application/json'
      end

      it 'should not response with 406 for same type without params' do
        expect(last_response.status).not_to be 406
      end

      it 'should response with given content type in headers' do
        expect(last_response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
      end
    end

    context 'precedence' do
      before do
        subject.format :json
        subject.namespace '/:id' do
          get do
            {
              params: params[:id]
            }
          end
          post do
            {
              params: params[:id]
            }
          end
          put do
            {
              params: params[:id]
            }
          end
        end
      end

      it 'route string params have higher precedence than body params' do
        post '/123', { id: 456 }.to_json
        expect(JSON.parse(last_response.body)['params']).to eq '123'
        put '/123', { id: 456 }.to_json
        expect(JSON.parse(last_response.body)['params']).to eq '123'
      end

      it 'route string params have higher precedence than URL params' do
        get '/123?id=456'
        expect(JSON.parse(last_response.body)['params']).to eq '123'
        post '/123?id=456'
        expect(JSON.parse(last_response.body)['params']).to eq '123'
      end
    end

    context 'sets a value to params' do
      it 'params' do
        subject.params do
          requires :a, type: String
        end
        subject.get '/foo' do
          params[:a] = 'bar'
        end

        get '/foo', a: 'foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('bar')
      end
    end
  end

  describe '#error!' do
    it 'accepts a message' do
      subject.get('/hey') do
        error! 'This is not valid.'
        'This is valid.'
      end

      get '/hey'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('This is not valid.')
    end

    it 'accepts a code' do
      subject.get('/hey') do
        error! 'Unauthorized.', 401
      end

      get '/hey'
      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq('Unauthorized.')
    end

    it 'accepts an object and render it in format' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403)
      end

      get '/hey.json'
      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq('{"dude":"rad"}')
    end

    it 'accepts a frozen object' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }.freeze, 403)
      end

      get '/hey.json'
      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq('{"dude":"rad"}')
    end

    it 'can specifiy headers' do
      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403, 'X-Custom' => 'value')
      end

      get '/hey.json'
      expect(last_response.status).to eq(403)
      expect(last_response.headers['X-Custom']).to eq('value')
    end

    it 'merges additional headers with headers set before call' do
      subject.before do
        header 'X-Before-Test', 'before-sample'
      end

      subject.get '/hey' do
        header 'X-Test', 'test-sample'
        error!({ 'dude' => 'rad' }, 403, 'X-Error' => 'error')
      end

      get '/hey.json'
      expect(last_response.headers['X-Before-Test']).to eq('before-sample')
      expect(last_response.headers['X-Test']).to eq('test-sample')
      expect(last_response.headers['X-Error']).to eq('error')
    end

    it 'does not merges additional headers with headers set after call' do
      subject.after do
        header 'X-After-Test', 'after-sample'
      end

      subject.get '/hey' do
        error!({ 'dude' => 'rad' }, 403, 'X-Error' => 'error')
      end

      get '/hey.json'
      expect(last_response.headers['X-Error']).to eq('error')
      expect(last_response.headers['X-After-Test']).to be_nil
    end

    it 'sets the status code for the endpoint' do
      memoized_endpoint = nil

      subject.get '/hey' do
        memoized_endpoint = self
        error!({ 'dude' => 'rad' }, 403, 'X-Custom' => 'value')
      end

      get '/hey.json'

      expect(memoized_endpoint.status).to eq(403)
    end
  end

  describe '#redirect' do
    it 'redirects to a url with status 302' do
      subject.get('/hey') do
        redirect '/ha'
      end
      get '/hey'
      expect(last_response.status).to eq 302
      expect(last_response.headers['Location']).to eq '/ha'
      expect(last_response.body).to eq 'This resource has been moved temporarily to /ha.'
    end

    it 'has status code 303 if it is not get request and it is http 1.1' do
      subject.post('/hey') do
        redirect '/ha'
      end
      post '/hey', {}, 'HTTP_VERSION' => 'HTTP/1.1'
      expect(last_response.status).to eq 303
      expect(last_response.headers['Location']).to eq '/ha'
      expect(last_response.body).to eq 'An alternate resource is located at /ha.'
    end

    it 'support permanent redirect' do
      subject.get('/hey') do
        redirect '/ha', permanent: true
      end
      get '/hey'
      expect(last_response.status).to eq 301
      expect(last_response.headers['Location']).to eq '/ha'
      expect(last_response.body).to eq 'This resource has been moved permanently to /ha.'
    end

    it 'allows for an optional redirect body override' do
      subject.get('/hey') do
        redirect '/ha', body: 'test body'
      end
      get '/hey'
      expect(last_response.body).to eq 'test body'
    end
  end

  it 'does not persist params between calls' do
    subject.post('/new') do
      params[:text]
    end

    post '/new', text: 'abc'
    expect(last_response.body).to eq('abc')

    post '/new', text: 'def'
    expect(last_response.body).to eq('def')
  end

  it 'resets all instance variables (except block) between calls' do
    subject.helpers do
      def memoized
        @memoized ||= params[:howdy]
      end
    end

    subject.get('/hello') do
      memoized
    end

    get '/hello?howdy=hey'
    expect(last_response.body).to eq('hey')
    get '/hello?howdy=yo'
    expect(last_response.body).to eq('yo')
  end

  it 'allows explicit return calls' do
    subject.get('/home') do
      return 'Hello'
    end

    get '/home'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('Hello')
  end

  describe '.generate_api_method' do
    it 'raises NameError if the method name is already in use' do
      expect do
        Grape::Endpoint.generate_api_method('version', &proc {})
      end.to raise_error(NameError)
    end
    it 'raises ArgumentError if a block is not given' do
      expect do
        Grape::Endpoint.generate_api_method('GET without a block method')
      end.to raise_error(ArgumentError)
    end
    it 'returns a Proc' do
      expect(Grape::Endpoint.generate_api_method('GET test for a proc', &proc {})).to be_a Proc
    end
  end

  context 'filters' do
    describe 'before filters' do
      it 'runs the before filter if set' do
        subject.before { env['before_test'] = 'OK' }
        subject.get('/before_test') { env['before_test'] }

        get '/before_test'
        expect(last_response.body).to eq('OK')
      end
    end

    describe 'after filters' do
      it 'overrides the response body if it sets it' do
        subject.after { body 'after' }
        subject.get('/after_test') { 'during' }
        get '/after_test'
        expect(last_response.body).to eq('after')
      end

      it 'does not override the response body with its return' do
        subject.after { 'after' }
        subject.get('/after_test') { 'body' }
        get '/after_test'
        expect(last_response.body).to eq('body')
      end
    end

    it 'allows adding to response with present' do
      subject.format :json
      subject.before { present :before, 'before' }
      subject.before_validation { present :before_validation, 'before_validation' }
      subject.after_validation { present :after_validation, 'after_validation' }
      subject.after { present :after, 'after' }
      subject.get :all_filters do
        present :endpoint, 'endpoint'
      end

      get '/all_filters'
      json = JSON.parse(last_response.body)
      expect(json.keys).to match_array %w[before before_validation after_validation endpoint after]
    end

    context 'when terminating the response with error!' do
      it 'breaks normal call chain' do
        called = []
        subject.before { called << 'before' }
        subject.before_validation { called << 'before_validation' }
        subject.after_validation { error! :oops, 500 }
        subject.after { called << 'after' }
        subject.get :error_filters do
          called << 'endpoint'
          ''
        end

        get '/error_filters'
        expect(last_response.status).to eql 500
        expect(called).to match_array %w[before before_validation]
      end

      it 'allows prior and parent filters of same type to run' do
        called = []
        subject.before { called << 'parent' }
        subject.namespace :parent do
          before { called << 'prior' }
          before { error! :oops, 500 }
          before { called << 'subsequent' }
          get :hello do
            called << :endpoint
            'Hello!'
          end
        end

        get '/parent/hello'
        expect(last_response.status).to eql 500
        expect(called).to match_array %w[parent prior]
      end
    end
  end

  context 'anchoring' do
    describe 'delete 204' do
      it 'allows for the anchoring option with a delete method' do
        subject.send(:delete, '/example', anchor: true) {}
        send(:delete, '/example/and/some/more')
        expect(last_response.status).to eql 404
      end

      it 'anchors paths by default for the delete method' do
        subject.send(:delete, '/example') {}
        send(:delete, '/example/and/some/more')
        expect(last_response.status).to eql 404
      end

      it 'responds to /example/and/some/more for the non-anchored delete method' do
        subject.send(:delete, '/example', anchor: false) {}
        send(:delete, '/example/and/some/more')
        expect(last_response.status).to eql 204
        expect(last_response.body).to be_empty
      end
    end

    describe 'delete 200, with response body' do
      it 'responds to /example/and/some/more for the non-anchored delete method' do
        subject.send(:delete, '/example', anchor: false) do
          status 200
          body 'deleted'
        end
        send(:delete, '/example/and/some/more')
        expect(last_response.status).to eql 200
        expect(last_response.body).not_to be_empty
      end
    end

    describe 'delete 200, with a return value (no explicit body)' do
      it 'responds to /example delete method' do
        subject.delete(:example) { 'deleted' }
        delete '/example'
        expect(last_response.status).to eql 200
        expect(last_response.body).not_to be_empty
      end
    end

    describe 'delete 204, with nil has return value (no explicit body)' do
      it 'responds to /example delete method' do
        subject.delete(:example) { nil }
        delete '/example'
        expect(last_response.status).to eql 204
        expect(last_response.body).to be_empty
      end
    end

    describe 'delete 204, with empty array has return value (no explicit body)' do
      it 'responds to /example delete method' do
        subject.delete(:example) { '' }
        delete '/example'
        expect(last_response.status).to eql 204
        expect(last_response.body).to be_empty
      end
    end

    describe 'all other' do
      %w[post get head put options patch].each do |verb|
        it "allows for the anchoring option with a #{verb.upcase} method" do
          subject.send(verb, '/example', anchor: true) do
            verb
          end
          send(verb, '/example/and/some/more')
          expect(last_response.status).to eql 404
        end

        it "anchors paths by default for the #{verb.upcase} method" do
          subject.send(verb, '/example') do
            verb
          end
          send(verb, '/example/and/some/more')
          expect(last_response.status).to eql 404
        end

        it "responds to /example/and/some/more for the non-anchored #{verb.upcase} method" do
          subject.send(verb, '/example', anchor: false) do
            verb
          end
          send(verb, '/example/and/some/more')
          expect(last_response.status).to eql verb == 'post' ? 201 : 200
          expect(last_response.body).to eql verb == 'head' ? '' : verb
        end
      end
    end
  end

  context 'request' do
    it 'is set to the url requested' do
      subject.get('/url') do
        request.url
      end
      get '/url'
      expect(last_response.body).to eq('http://example.org/url')
    end
    ['v1', :v1].each do |version|
      it "should include version #{version}" do
        subject.version version, using: :path
        subject.get('/url') do
          request.url
        end
        get "/#{version}/url"
        expect(last_response.body).to eq("http://example.org/#{version}/url")
      end
    end
    it 'should include prefix' do
      subject.version 'v1', using: :path
      subject.prefix 'api'
      subject.get('/url') do
        request.url
      end
      get '/api/v1/url'
      expect(last_response.body).to eq('http://example.org/api/v1/url')
    end
  end

  context 'version headers' do
    before do
      # NOTE: a 404 is returned instead of the 406 if cascade: false is not set.
      subject.version 'v1', using: :header, vendor: 'ohanapi', cascade: false
      subject.get '/test' do
        'Hello!'
      end
    end

    it 'result in a 406 response if they are invalid' do
      get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.ohanapi.v1+json'
      expect(last_response.status).to eq(406)
    end

    it 'result in a 406 response if they cannot be parsed by rack-accept' do
      get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.ohanapi.v1+json; version=1'
      expect(last_response.status).to eq(406)
    end
  end

  context 'binary' do
    before do
      subject.get do
        file FileStreamer.new(__FILE__)
      end
    end

    it 'suports stream objects in response' do
      get '/'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq File.read(__FILE__)
    end
  end

  context 'validation errors' do
    before do
      subject.before do
        header['Access-Control-Allow-Origin'] = '*'
      end
      subject.params do
        requires :id, type: String
      end
      subject.get do
        'should not get here'
      end
    end

    it 'returns the errors, and passes headers' do
      get '/'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'id is missing'
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  context 'instrumentation' do
    before do
      subject.before do
        # Placeholder
      end
      subject.get do
        'hello'
      end

      @events = []
      @subscriber = ActiveSupport::Notifications.subscribe(/grape/) do |*args|
        @events << ActiveSupport::Notifications::Event.new(*args)
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe(@subscriber)
    end

    it 'notifies AS::N' do
      get '/'

      # In order that the events finalized (time each block ended)
      expect(@events).to contain_exactly(
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: a_collection_containing_exactly(an_instance_of(Proc)),
                                                                       type: :before }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :before_validation }),
        have_attributes(name: 'endpoint_run_validators.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                          validators: [],
                                                                          request: a_kind_of(Grape::Request) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :after_validation }),
        have_attributes(name: 'endpoint_render.grape',      payload: { endpoint: a_kind_of(Grape::Endpoint) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :after }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :finally }),
        have_attributes(name: 'endpoint_run.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                               env: an_instance_of(Hash) }),
        have_attributes(name: 'format_response.grape', payload: { env: an_instance_of(Hash),
                                                                  formatter: a_kind_of(Module) })
      )

      # In order that events were initialized
      expect(@events.sort_by(&:time)).to contain_exactly(
        have_attributes(name: 'endpoint_run.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                               env: an_instance_of(Hash) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: a_collection_containing_exactly(an_instance_of(Proc)),
                                                                       type: :before }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :before_validation }),
        have_attributes(name: 'endpoint_run_validators.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                          validators: [],
                                                                          request: a_kind_of(Grape::Request) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :after_validation }),
        have_attributes(name: 'endpoint_render.grape',      payload: { endpoint: a_kind_of(Grape::Endpoint) }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :after }),
        have_attributes(name: 'endpoint_run_filters.grape', payload: { endpoint: a_kind_of(Grape::Endpoint),
                                                                       filters: [],
                                                                       type: :finally }),
        have_attributes(name: 'format_response.grape', payload: { env: an_instance_of(Hash),
                                                                  formatter: a_kind_of(Module) })
      )
    end
  end
end
