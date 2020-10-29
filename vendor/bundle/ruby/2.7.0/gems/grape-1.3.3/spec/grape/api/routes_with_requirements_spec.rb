# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  context 'get' do
    it 'routes to a namespace param with dots' do
      subject.namespace ':ns_with_dots', requirements: { ns_with_dots: %r{[^\/]+} } do
        get '/' do
          params[:ns_with_dots]
        end
      end

      get '/test.id.with.dots'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'test.id.with.dots'
    end

    it 'routes to a path with multiple params with dots' do
      subject.get ':id_with_dots/:another_id_with_dots', requirements: { id_with_dots: %r{[^\/]+},
                                                                         another_id_with_dots: %r{[^\/]+} } do
        "#{params[:id_with_dots]}/#{params[:another_id_with_dots]}"
      end

      get '/test.id/test2.id'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'test.id/test2.id'
    end

    it 'routes to namespace and path params with dots, with overridden requirements' do
      subject.namespace ':ns_with_dots', requirements: { ns_with_dots: %r{[^\/]+} } do
        get ':another_id_with_dots',     requirements: { ns_with_dots: %r{[^\/]+},
                                                         another_id_with_dots: %r{[^\/]+} } do
          "#{params[:ns_with_dots]}/#{params[:another_id_with_dots]}"
        end
      end

      get '/test.id/test2.id'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'test.id/test2.id'
    end

    it 'routes to namespace and path params with dots, with merged requirements' do
      subject.namespace ':ns_with_dots', requirements: { ns_with_dots: %r{[^\/]+} } do
        get ':another_id_with_dots',     requirements: { another_id_with_dots: %r{[^\/]+} } do
          "#{params[:ns_with_dots]}/#{params[:another_id_with_dots]}"
        end
      end

      get '/test.id/test2.id'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'test.id/test2.id'
    end
  end
end
