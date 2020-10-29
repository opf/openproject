# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::RegexpValidator do
  module ValidationsSpec
    module RegexpValidatorSpec
      class API < Grape::API
        default_format :json

        resources :custom_message do
          params do
            requires :name, regexp: { value: /^[a-z]+$/, message: 'format is invalid' }
          end
          get do
          end

          params do
            requires :names, type: { value: Array[String], message: 'can\'t be nil' }, regexp: { value: /^[a-z]+$/, message: 'format is invalid' }
          end
          get 'regexp_with_array' do
          end
        end

        params do
          requires :name, regexp: /^[a-z]+$/
        end
        get do
        end

        params do
          requires :names, type: Array[String], regexp: /^[a-z]+$/
        end
        get 'regexp_with_array' do
        end

        params do
          requires :people, type: Hash do
            requires :names, type: Array[String], regexp: /^[a-z]+$/
          end
        end
        get 'nested_regexp_with_array' do
        end
      end
    end
  end

  def app
    ValidationsSpec::RegexpValidatorSpec::API
  end

  context 'custom validation message' do
    context 'with invalid input' do
      it 'refuses inapppopriate' do
        get '/custom_message', name: 'invalid name'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"name format is invalid"}')
      end

      it 'refuses empty' do
        get '/custom_message', name: ''
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"name format is invalid"}')
      end
    end

    it 'accepts nil' do
      get '/custom_message', name: nil
      expect(last_response.status).to eq(200)
    end

    it 'accepts valid input' do
      get '/custom_message', name: 'bob'
      expect(last_response.status).to eq(200)
    end

    context 'regexp with array' do
      it 'refuses inapppopriate items' do
        get '/custom_message/regexp_with_array', names: ['invalid name', 'abc']
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"names format is invalid"}')
      end

      it 'refuses empty items' do
        get '/custom_message/regexp_with_array', names: ['', 'abc']
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"names format is invalid"}')
      end

      it 'refuses nil items' do
        get '/custom_message/regexp_with_array', names: [nil, 'abc']
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"names can\'t be nil"}')
      end

      it 'accepts valid items' do
        get '/custom_message/regexp_with_array', names: ['bob']
        expect(last_response.status).to eq(200)
      end

      it 'accepts nil instead of array' do
        get '/custom_message/regexp_with_array', names: nil
        expect(last_response.status).to eq(200)
      end
    end
  end

  context 'invalid input' do
    it 'refuses inapppopriate' do
      get '/', name: 'invalid name'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"name is invalid"}')
    end

    it 'refuses empty' do
      get '/', name: ''
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"name is invalid"}')
    end
  end

  it 'accepts nil' do
    get '/', name: nil
    expect(last_response.status).to eq(200)
  end

  it 'accepts valid input' do
    get '/', name: 'bob'
    expect(last_response.status).to eq(200)
  end

  context 'regexp with array' do
    it 'refuses inapppopriate items' do
      get '/regexp_with_array', names: ['invalid name', 'abc']
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"names is invalid"}')
    end

    it 'refuses empty items' do
      get '/regexp_with_array', names: ['', 'abc']
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"names is invalid"}')
    end

    it 'refuses nil items' do
      get '/regexp_with_array', names: [nil, 'abc']
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"names is invalid"}')
    end

    it 'accepts valid items' do
      get '/regexp_with_array', names: ['bob']
      expect(last_response.status).to eq(200)
    end

    it 'accepts nil instead of array' do
      get '/regexp_with_array', names: nil
      expect(last_response.status).to eq(200)
    end
  end

  context 'nested regexp with array' do
    it 'refuses inapppopriate' do
      get '/nested_regexp_with_array', people: 'invalid name'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"people is invalid, people[names] is missing, people[names] is invalid"}')
    end
  end
end
