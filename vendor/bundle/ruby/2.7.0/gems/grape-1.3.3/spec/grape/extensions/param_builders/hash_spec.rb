# frozen_string_literal: true

require 'spec_helper'

describe Grape::Extensions::Hash::ParamBuilder do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  describe 'in an endpoint' do
    context '#params' do
      before do
        subject.params do
          build_with Grape::Extensions::Hash::ParamBuilder
        end

        subject.get do
          params.class
        end
      end

      it 'should be of type Hash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hash')
      end
    end
  end

  describe 'in an api' do
    before do
      subject.send(:include, Grape::Extensions::Hash::ParamBuilder)
    end

    context '#params' do
      before do
        subject.get do
          params.class
        end
      end

      it 'should be Hash' do
        get '/'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hash')
      end
    end

    it 'symbolizes params keys' do
      subject.params do
        optional :a, type: Hash do
          optional :b, type: Hash do
            optional :c, type: String
          end
          optional :d, type: Array
        end
      end

      subject.get '/foo' do
        [params[:a][:b][:c], params[:a][:d]]
      end

      get '/foo', 'a' => { b: { c: 'bar' }, 'd' => ['foo'] }
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", ["foo"]]')
    end

    it 'symbolizes the params' do
      subject.params do
        build_with Grape::Extensions::Hash::ParamBuilder
        requires :a, type: String
      end

      subject.get '/foo' do
        [params[:a], params['a']]
      end

      get '/foo', a: 'bar'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('["bar", nil]')
    end
  end
end
