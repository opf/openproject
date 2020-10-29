# frozen_string_literal: true

require 'spec_helper'

describe Grape::API::Helpers do
  let(:user) { 'Miguel Caneo' }
  let(:id)   { '42' }

  module InheritedHelpersSpec
    class SuperClass < Grape::API
      helpers do
        params(:superclass_params) { requires :id, type: String }

        def current_user
          params[:user]
        end
      end
    end

    class OverriddenSubClass < SuperClass
      params { use :superclass_params }

      helpers do
        def current_user
          "#{params[:user]} with id"
        end
      end

      get 'resource' do
        "#{current_user}: #{params['id']}"
      end
    end

    class SubClass < SuperClass
      params { use :superclass_params }

      get 'resource' do
        "#{current_user}: #{params['id']}"
      end
    end

    class Example < SubClass
      params { use :superclass_params }

      get 'resource' do
        "#{current_user}: #{params['id']}"
      end
    end
  end

  context 'non overriding subclass' do
    subject { InheritedHelpersSpec::SubClass }

    def app
      subject
    end

    context 'given expected params' do
      it 'inherits helpers from a superclass' do
        get '/resource', id: id, user: user
        expect(last_response.body).to eq("#{user}: #{id}")
      end
    end

    context 'with lack of expected params' do
      it 'returns missing error' do
        get '/resource'
        expect(last_response.body).to eq('id is missing')
      end
    end
  end

  context 'overriding subclass' do
    subject { InheritedHelpersSpec::OverriddenSubClass }

    def app
      subject
    end

    context 'given expected params' do
      it 'overrides helpers from a superclass' do
        get '/resource', id: id, user: user
        expect(last_response.body).to eq("#{user} with id: #{id}")
      end
    end

    context 'with lack of expected params' do
      it 'returns missing error' do
        get '/resource'
        expect(last_response.body).to eq('id is missing')
      end
    end
  end

  context 'example subclass' do
    subject { InheritedHelpersSpec::Example }

    def app
      subject
    end

    context 'given expected params' do
      it 'inherits helpers from a superclass' do
        get '/resource', id: id, user: user
        expect(last_response.body).to eq("#{user}: #{id}")
      end
    end

    context 'with lack of expected params' do
      it 'returns missing error' do
        get '/resource'
        expect(last_response.body).to eq('id is missing')
      end
    end
  end
end
