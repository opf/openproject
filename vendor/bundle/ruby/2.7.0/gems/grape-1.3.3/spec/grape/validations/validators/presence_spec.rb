# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::PresenceValidator do
  subject do
    Class.new(Grape::API) do
      format :json
    end
  end
  def app
    subject
  end

  context 'without validation' do
    before do
      subject.resource :bacons do
        get do
          'All the bacon'
        end
      end
    end
    it 'does not validate for any params' do
      get '/bacons'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('All the bacon'.to_json)
    end
  end

  context 'with a custom validation message' do
    before do
      subject.resource :requires do
        params do
          requires :email, type: String, allow_blank: { value: false, message: 'has no value' }, regexp: { value: /^\S+$/, message: 'format is invalid' }, message: 'is required'
        end
        get do
          'Hello'
        end
      end
    end
    it 'requires when missing' do
      get '/requires'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"email is required, email has no value"}')
    end
    it 'requires when empty' do
      get '/requires', email: ''
      expect(last_response.body).to eq('{"error":"email has no value, email format is invalid"}')
    end
    it 'valid when set' do
      get '/requires', email: 'bob@example.com'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Hello'.to_json)
    end
  end

  context 'with a required regexp parameter supplied in the POST body' do
    before do
      subject.format :json
      subject.params do
        requires :id, regexp: /^[0-9]+$/
      end
      subject.post do
        { ret: params[:id] }
      end
    end
    it 'validates id' do
      post '/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"id is missing"}')

      io = StringIO.new('{"id" : "a56b"}')
      post '/', {}, 'rack.input' => io, 'CONTENT_TYPE' => 'application/json', 'CONTENT_LENGTH' => io.length
      expect(last_response.body).to eq('{"error":"id is invalid"}')
      expect(last_response.status).to eq(400)

      io = StringIO.new('{"id" : 56}')
      post '/', {}, 'rack.input' => io, 'CONTENT_TYPE' => 'application/json', 'CONTENT_LENGTH' => io.length
      expect(last_response.body).to eq('{"ret":56}')
      expect(last_response.status).to eq(201)
    end
  end

  context 'with a required non-empty string' do
    before do
      subject.params do
        requires :email, type: String, allow_blank: false, regexp: /^\S+$/
      end
      subject.get do
        'Hello'
      end
    end
    it 'requires when missing' do
      get '/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"email is missing, email is empty"}')
    end
    it 'requires when empty' do
      get '/', email: ''
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"email is empty, email is invalid"}')
    end
    it 'valid when set' do
      get '/', email: 'bob@example.com'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Hello'.to_json)
    end
  end

  context 'with multiple parameters per requires' do
    before do
      subject.params do
        requires :one, :two
      end
      subject.get '/single-requires' do
        'Hello'
      end

      subject.params do
        requires :one
        requires :two
      end
      subject.get '/multiple-requires' do
        'Hello'
      end
    end
    it 'validates for all defined params' do
      get '/single-requires'
      expect(last_response.status).to eq(400)
      single_requires_error = last_response.body

      get '/multiple-requires'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq(single_requires_error)
    end
  end

  context 'with required parameters and no type' do
    before do
      subject.params do
        requires :name, :company
      end
      subject.get do
        'Hello'
      end
    end
    it 'validates name, company' do
      get '/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"name is missing, company is missing"}')

      get '/', name: 'Bob'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"company is missing"}')

      get '/', name: 'Bob', company: 'TestCorp'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Hello'.to_json)
    end
  end

  context 'with nested parameters' do
    before do
      subject.params do
        requires :user, type: Hash do
          requires :first_name
          requires :last_name
        end
      end
      subject.get '/nested' do
        'Nested'
      end
    end
    it 'validates nested parameters' do
      get '/nested'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"user is missing, user[first_name] is missing, user[last_name] is missing"}')

      get '/nested', user: { first_name: 'Billy' }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"user[last_name] is missing"}')

      get '/nested', user: { first_name: 'Billy', last_name: 'Bob' }
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Nested'.to_json)
    end
  end

  context 'with triply nested required parameters' do
    before do
      subject.params do
        requires :admin, type: Hash do
          requires :admin_name
          requires :super, type: Hash do
            requires :user, type: Hash do
              requires :first_name
              requires :last_name
            end
          end
        end
      end
      subject.get '/nested_triple' do
        'Nested triple'
      end
    end
    it 'validates triple nested parameters' do
      get '/nested_triple'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to include '{"error":"admin is missing'

      get '/nested_triple', user: { first_name: 'Billy' }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to include '{"error":"admin is missing'

      get '/nested_triple', admin: { super: { first_name: 'Billy' } }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"admin[admin_name] is missing, admin[super][user] is missing, admin[super][user][first_name] is missing, admin[super][user][last_name] is missing"}')

      get '/nested_triple', super: { user: { first_name: 'Billy', last_name: 'Bob' } }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to include '{"error":"admin is missing'

      get '/nested_triple', admin: { super: { user: { first_name: 'Billy' } } }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"admin[admin_name] is missing, admin[super][user][last_name] is missing"}')

      get '/nested_triple', admin: { admin_name: 'admin', super: { user: { first_name: 'Billy' } } }
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"admin[super][user][last_name] is missing"}')

      get '/nested_triple', admin: { admin_name: 'admin', super: { user: { first_name: 'Billy', last_name: 'Bob' } } }
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Nested triple'.to_json)
    end
  end

  context 'with reused parameter documentation once required and once optional' do
    before do
      docs = { name: { type: String, desc: 'some name' } }

      subject.params do
        requires :all, using: docs
      end
      subject.get '/required' do
        'Hello required'
      end

      subject.params do
        optional :all, using: docs
      end
      subject.get '/optional' do
        'Hello optional'
      end
    end
    it 'works with required' do
      get '/required'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"name is missing"}')

      get '/required', name: 'Bob'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Hello required'.to_json)
    end
    it 'works with optional' do
      get '/optional'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Hello optional'.to_json)

      get '/optional', name: 'Bob'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('Hello optional'.to_json)
    end
  end

  context 'with a custom type' do
    it 'does not validate their type when it is missing' do
      class CustomType
        def self.parse(value)
          return if value.blank?

          new
        end
      end

      subject.params do
        requires :custom, type: CustomType
      end
      subject.get '/custom' do
        'custom'
      end

      get 'custom'

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"custom is missing"}')

      get 'custom', custom: 'filled'

      expect(last_response.status).to eq(200)
    end
  end
end
