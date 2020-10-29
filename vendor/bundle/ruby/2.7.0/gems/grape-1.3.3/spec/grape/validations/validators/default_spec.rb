# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::DefaultValidator do
  module ValidationsSpec
    module DefaultValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          optional :id
          optional :type, default: 'default-type'
        end
        get '/' do
          { id: params[:id], type: params[:type] }
        end

        params do
          optional :type1, default: 'default-type1'
          optional :type2, default: 'default-type2'
        end
        get '/user' do
          { type1: params[:type1], type2: params[:type2] }
        end

        params do
          requires :id
          optional :type1, default: 'default-type1'
          optional :type2, default: 'default-type2'
        end

        get '/message' do
          { id: params[:id], type1: params[:type1], type2: params[:type2] }
        end

        params do
          optional :random, default: -> { Random.rand }
          optional :not_random, default: Random.rand
        end
        get '/numbers' do
          { random_number: params[:random], non_random_number: params[:non_random_number] }
        end

        params do
          optional :array, type: Array do
            requires :name
            optional :with_default, default: 'default'
          end
        end
        get '/array' do
          { array: params[:array] }
        end

        params do
          requires :thing1
          optional :more_things, type: Array do
            requires :nested_thing
            requires :other_thing, default: 1
          end
        end
        get '/optional_array' do
          { thing1: params[:thing1] }
        end

        params do
          requires :root, type: Hash do
            optional :some_things, type: Array do
              requires :foo
              optional :options, type: Array do
                requires :name, type: String
                requires :value, type: String
              end
            end
          end
        end
        get '/nested_optional_array' do
          { root: params[:root] }
        end

        params do
          requires :root, type: Hash do
            optional :some_things, type: Array do
              requires :foo
              optional :options, type: Array do
                optional :name, type: String
                optional :value, type: String
              end
            end
          end
        end
        get '/another_nested_optional_array' do
          { root: params[:root] }
        end
      end
    end
  end

  def app
    ValidationsSpec::DefaultValidatorSpec::API
  end

  it 'lets you leave required values nested inside an optional blank' do
    get '/optional_array', thing1: 'stuff'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ thing1: 'stuff' }.to_json)
  end

  it 'allows optional arrays to be omitted' do
    params = { some_things:
                [{ foo: 'one', options: [{ name: 'wat', value: 'nope' }] },
                 { foo: 'two' },
                 { foo: 'three', options: [{ name: 'wooop', value: 'yap' }] }] }
    get '/nested_optional_array', root: params
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ root: params }.to_json)
  end

  it 'does not allows faulty optional arrays' do
    params = { some_things:
                 [
                   { foo: 'one', options: [{ name: 'wat', value: 'nope' }] },
                   { foo: 'two', options: [{ name: 'wat' }] },
                   { foo: 'three' }
                 ] }
    error = { error: 'root[some_things][1][options][0][value] is missing' }
    get '/nested_optional_array', root: params
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq(error.to_json)
  end

  it 'allows optional arrays with optional params' do
    params = { some_things:
                 [
                   { foo: 'one', options: [{ value: 'nope' }] },
                   { foo: 'two', options: [{ name: 'wat' }] },
                   { foo: 'three' }
                 ] }
    get '/another_nested_optional_array', root: params
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ root: params }.to_json)
  end

  it 'set default value for optional param' do
    get('/')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ id: nil, type: 'default-type' }.to_json)
  end

  it 'set default values for optional params' do
    get('/user')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ type1: 'default-type1', type2: 'default-type2' }.to_json)
  end

  it 'set default values for missing params in the request' do
    get('/user?type2=value2')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ type1: 'default-type1', type2: 'value2' }.to_json)
  end

  it 'set default values for optional params and allow to use required fields in the same time' do
    get('/message?id=1')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ id: '1', type1: 'default-type1', type2: 'default-type2' }.to_json)
  end

  it 'sets lambda based defaults at the time of call' do
    get('/numbers')
    expect(last_response.status).to eq(200)
    before = JSON.parse(last_response.body)
    get('/numbers')
    expect(last_response.status).to eq(200)
    after = JSON.parse(last_response.body)

    expect(before['non_random_number']).to eq(after['non_random_number'])
    expect(before['random_number']).not_to eq(after['random_number'])
  end

  it 'sets default values for grouped arrays' do
    get('/array?array[][name]=name&array[][name]=name2&array[][with_default]=bar2')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq({ array: [{ name: 'name', with_default: 'default' }, { name: 'name2', with_default: 'bar2' }] }.to_json)
  end

  context 'optional group with defaults' do
    subject do
      Class.new(Grape::API) do
        default_format :json
      end
    end

    def app
      subject
    end

    context 'optional array without default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_array, type: Array do
            optional :foo_in_optional_array, default: 'bar'
          end
        end
        subject.post '/optional_array' do
          { optional_array: params[:optional_array] }
        end
      end

      it 'returns nil for optional array if param is not provided' do
        post '/optional_array'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_array: nil }.to_json)
      end
    end

    context 'optional array with default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_array_with_default, type: Array, default: [] do
            optional :foo_in_optional_array, default: 'bar'
          end
        end
        subject.post '/optional_array_with_default' do
          { optional_array_with_default: params[:optional_array_with_default] }
        end
      end

      it 'sets default value for optional array if param is not provided' do
        post '/optional_array_with_default'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_array_with_default: [] }.to_json)
      end
    end

    context 'optional hash without default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_hash_without_default, type: Hash do
            optional :foo_in_optional_hash, default: 'bar'
          end
        end
        subject.post '/optional_hash_without_default' do
          { optional_hash_without_default: params[:optional_hash_without_default] }
        end
      end

      it 'returns nil for optional hash if param is not provided' do
        post '/optional_hash_without_default'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_hash_without_default: nil }.to_json)
      end

      it 'does not fail even if invalid params is passed to default validator' do
        expect { post '/optional_hash_without_default', optional_hash_without_default: '5678' }.not_to raise_error
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq({ error: 'optional_hash_without_default is invalid' }.to_json)
      end
    end

    context 'optional hash with default value includes optional param with default value' do
      before do
        subject.params do
          optional :optional_hash_with_default, type: Hash, default: {} do
            optional :foo_in_optional_hash, default: 'bar'
          end
        end
        subject.post '/optional_hash_with_default_empty_hash' do
          { optional_hash_with_default: params[:optional_hash_with_default] }
        end

        subject.params do
          optional :optional_hash_with_default, type: Hash, default: { foo_in_optional_hash: 'parent_default' } do
            optional :some_param
            optional :foo_in_optional_hash, default: 'own_default'
          end
        end
        subject.post '/optional_hash_with_default_inner_params' do
          { foo_in_optional_hash: params[:optional_hash_with_default][:foo_in_optional_hash] }
        end
      end

      it 'sets default value for optional hash if param is not provided' do
        post '/optional_hash_with_default_empty_hash'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ optional_hash_with_default: {} }.to_json)
      end

      it 'sets default value from parent defaults for inner param if parent param is not provided' do
        post '/optional_hash_with_default_inner_params'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ foo_in_optional_hash: 'parent_default' }.to_json)
      end

      it 'sets own default value for inner param if parent param is provided' do
        post '/optional_hash_with_default_inner_params', optional_hash_with_default: { some_param: 'param' }
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ foo_in_optional_hash: 'own_default' }.to_json)
      end
    end
  end

  context 'optional with nil as value' do
    subject do
      Class.new(Grape::API) do
        default_format :json
      end
    end

    def app
      subject
    end

    context 'primitive types' do
      [
        [Integer, 0],
        [Integer, 42],
        [Float, 0.0],
        [Float, 4.2],
        [BigDecimal, 0.0],
        [BigDecimal, 4.2],
        [Numeric, 0],
        [Numeric, 42],
        [Date, Date.today],
        [DateTime, DateTime.now],
        [Time, Time.now],
        [Time, Time.at(0)],
        [Grape::API::Boolean, false],
        [String, ''],
        [String, 'non-empty-string'],
        [Symbol, :symbol],
        [TrueClass, true],
        [FalseClass, false]
      ].each do |type, default|
        it 'respects the default value' do
          subject.params do
            optional :param, type: type, default: default
          end
          subject.get '/default_value' do
            params[:param]
          end

          get '/default_value', param: nil
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(default.to_json)
        end
      end
    end

    context 'structures types' do
      [
        [Hash, {}],
        [Hash, { test: 'non-empty' }],
        [Array, []],
        [Array, ['non-empty']],
        [Array[Integer], []],
        [Set, []],
        [Set, [1]]
      ].each do |type, default|
        it 'respects the default value' do
          subject.params do
            optional :param, type: type, default: default
          end
          subject.get '/default_value' do
            params[:param]
          end

          get '/default_value', param: nil
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(default.to_json)
        end
      end
    end

    context 'special types' do
      [
        [JSON, ''],
        [JSON, { test: 'non-empty-string' }.to_json],
        [Array[JSON], []],
        [Array[JSON], [{ test: 'non-empty-string' }.to_json]],
        [::File, ''],
        [::File, { test: 'non-empty-string' }.to_json],
        [Rack::Multipart::UploadedFile, ''],
        [Rack::Multipart::UploadedFile, { test: 'non-empty-string' }.to_json]
      ].each do |type, default|
        it 'respects the default value' do
          subject.params do
            optional :param, type: type, default: default
          end
          subject.get '/default_value' do
            params[:param]
          end

          get '/default_value', param: nil
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(default.to_json)
        end
      end
    end

    context 'variant-member-type collections' do
      [
        [Array[Integer, String], [0, '']],
        [Array[Integer, String], [42, 'non-empty-string']],
        [[Integer, String, Array[Integer, String]], [0, '', [0, '']]],
        [[Integer, String, Array[Integer, String]], [42, 'non-empty-string', [42, 'non-empty-string']]]
      ].each do |type, default|
        it 'respects the default value' do
          subject.params do
            optional :param, type: type, default: default
          end
          subject.get '/default_value' do
            params[:param]
          end

          get '/default_value', param: nil
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(default.to_json)
        end
      end
    end
  end
end
