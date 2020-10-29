# frozen_string_literal: true

require 'spec_helper'

describe Grape::API do
  describe '.recognize_path' do
    subject { Class.new(Grape::API) }

    it 'fetches endpoint by given path' do
      subject.get('/foo/:id') {}
      subject.get('/bar/:id') {}
      subject.get('/baz/:id') {}

      actual = subject.recognize_path('/bar/1234').routes[0].origin
      expect(actual).to eq('/bar/:id')
    end

    it 'returns nil if given path does not match with registered routes' do
      subject.get {}
      expect(subject.recognize_path('/bar/1234')).to be_nil
    end
  end
end
