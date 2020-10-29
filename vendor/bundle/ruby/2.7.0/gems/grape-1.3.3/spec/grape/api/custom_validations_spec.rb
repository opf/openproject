# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations do
  context 'using a custom length validator' do
    before do
      module CustomValidationsSpec
        class DefaultLength < Grape::Validations::Base
          def validate_param!(attr_name, params)
            @option = params[:max].to_i if params.key?(:max)
            return if params[attr_name].length <= @option
            raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: "must be at the most #{@option} characters long")
          end
        end
      end
    end
    subject do
      Class.new(Grape::API) do
        params do
          requires :text, default_length: 140
        end
        get do
          'bacon'
        end
      end
    end

    def app
      subject
    end

    it 'under 140 characters' do
      get '/', text: 'abc'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end
    it 'over 140 characters' do
      get '/', text: 'a' * 141
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text must be at the most 140 characters long'
    end
    it 'specified in the query string' do
      get '/', text: 'a' * 141, max: 141
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end
  end

  context 'using a custom body-only validator' do
    before do
      module CustomValidationsSpec
        class InBody < Grape::Validations::PresenceValidator
          def validate(request)
            validate!(request.env['api.request.body'])
          end
        end
      end
    end
    subject do
      Class.new(Grape::API) do
        params do
          requires :text, in_body: true
        end
        get do
          'bacon'
        end
      end
    end

    def app
      subject
    end

    it 'allows field in body' do
      get '/', text: 'abc'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end
    it 'ignores field in query' do
      get '/', nil, text: 'abc'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text is missing'
    end
  end

  context 'using a custom validator with message_key' do
    before do
      module CustomValidationsSpec
        class WithMessageKey < Grape::Validations::PresenceValidator
          def validate_param!(attr_name, _params)
            raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: :presence)
          end
        end
      end
    end
    subject do
      Class.new(Grape::API) do
        params do
          requires :text, with_message_key: true
        end
        get do
          'bacon'
        end
      end
    end

    def app
      subject
    end

    it 'fails with message' do
      get '/', text: 'foobar'
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text is missing'
    end
  end

  context 'using a custom request/param validator' do
    before do
      module CustomValidationsSpec
        class Admin < Grape::Validations::Base
          def validate(request)
            # return if the param we are checking was not in request
            # @attrs is a list containing the attribute we are currently validating
            return unless request.params.key? @attrs.first
            # check if admin flag is set to true
            return unless @option
            # check if user is admin or not
            # as an example get a token from request and check if it's admin or not
            raise Grape::Exceptions::Validation.new(params: @attrs, message: 'Can not set Admin only field.') unless request.headers['X-Access-Token'] == 'admin'
          end
        end
      end
    end
    subject do
      Class.new(Grape::API) do
        params do
          optional :admin_field, type: String, admin: true
          optional :non_admin_field, type: String
          optional :admin_false_field, type: String, admin: false
        end
        get do
          'bacon'
        end
      end
    end

    def app
      subject
    end

    it 'fail when non-admin user sets an admin field' do
      get '/', admin_field: 'tester', non_admin_field: 'toaster'
      expect(last_response.status).to eq 400
      expect(last_response.body).to include 'Can not set Admin only field.'
    end

    it 'does not fail when we send non-admin fields only' do
      get '/', non_admin_field: 'toaster'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'does not fail when we send non-admin and admin=false fields only' do
      get '/', non_admin_field: 'toaster', admin_false_field: 'test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'does not fail when we send admin fields and we are admin' do
      header 'X-Access-Token', 'admin'
      get '/', admin_field: 'tester', non_admin_field: 'toaster', admin_false_field: 'test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end

    it 'fails when we send admin fields and we are not admin' do
      header 'X-Access-Token', 'user'
      get '/', admin_field: 'tester', non_admin_field: 'toaster', admin_false_field: 'test'
      expect(last_response.status).to eq 400
      expect(last_response.body).to include 'Can not set Admin only field.'
    end
  end
end
