# frozen_string_literal: true

# see https://github.com/ruby-grape/grape/issues/1348

require 'spec_helper'

def namespace
  raise
end

describe Grape::API do
  subject do
    Class.new(Grape::API) do
      format :json
      get do
        { ok: true }
      end
    end
  end

  def app
    subject
  end

  context 'with a global namespace function' do
    it 'works' do
      get '/'
      expect(last_response.status).to eq 200
    end
  end
end
