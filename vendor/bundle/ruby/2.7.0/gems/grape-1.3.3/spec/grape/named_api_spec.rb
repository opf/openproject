# frozen_string_literal: true

require 'spec_helper'

describe 'A named API' do
  subject(:api_name) { NamedAPI.endpoints.last.options[:for].to_s }

  let(:api) do
    Class.new(Grape::API) do
      get 'test' do
        'response'
      end
    end
  end

  before { stub_const('NamedAPI', api) }

  it 'can access the name of the API' do
    expect(api_name).to eq 'NamedAPI'
  end
end
