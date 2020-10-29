# frozen_string_literal: true

require 'spec_helper'

describe Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe 'in an endpoint' do
    context '#params' do
      before do
        subject.params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
        end

        subject.get do
          params.class
        end
      end

      it 'should be of type Hash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('ActiveSupport::HashWithIndifferentAccess')
      end
    end
  end

  describe 'in an api' do
    before do
      subject.send(:include, Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder)
    end

    context '#params' do
      before do
        subject.get do
          params.class
        end
      end

      it 'is a Hash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('ActiveSupport::HashWithIndifferentAccess')
      end

      it 'parses sub hash params' do
        subject.params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder

          optional :a, type: Hash do
            optional :b, type: Hash do
              optional :c, type: String
            end
            optional :d, type: Array
          end
        end

        subject.get '/foo' do
          [params[:a]['b'][:c], params['a'][:d]]
        end

        get '/foo', a: { b: { c: 'bar' }, d: ['foo'] }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('["bar", ["foo"]]')
      end

      it 'params are indifferent to symbol or string keys' do
        subject.params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
          optional :a, type: Hash do
            optional :b, type: Hash do
              optional :c, type: String
            end
            optional :d, type: Array
          end
        end

        subject.get '/foo' do
          [params[:a]['b'][:c], params['a'][:d]]
        end

        get '/foo', 'a' => { b: { c: 'bar' }, 'd' => ['foo'] }
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('["bar", ["foo"]]')
      end

      it 'responds to string keys' do
        subject.params do
          build_with Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
          requires :a, type: String
        end

        subject.get '/foo' do
          [params[:a], params['a']]
        end

        get '/foo', a: 'bar'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('["bar", "bar"]')
      end
    end
  end
end
