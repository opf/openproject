# frozen_string_literal: true

require 'spec_helper'

describe Grape::Middleware::Auth::DSL do
  subject { Class.new(Grape::API) }

  let(:block) { ->() {} }
  let(:settings) do
    {
      opaque: 'secret',
      proc: block,
      realm: 'API Authorization',
      type: :http_digest
    }
  end

  describe '.auth' do
    it 'stets auth parameters' do
      expect(subject.base_instance).to receive(:use).with(Grape::Middleware::Auth::Base, settings)

      subject.auth :http_digest, realm: settings[:realm], opaque: settings[:opaque], &settings[:proc]
      expect(subject.auth).to eq(settings)
    end

    it 'can be called multiple times' do
      expect(subject.base_instance).to receive(:use).with(Grape::Middleware::Auth::Base, settings)
      expect(subject.base_instance).to receive(:use).with(Grape::Middleware::Auth::Base, settings.merge(realm: 'super_secret'))

      subject.auth :http_digest, realm: settings[:realm], opaque: settings[:opaque], &settings[:proc]
      first_settings = subject.auth

      subject.auth :http_digest, realm: 'super_secret', opaque: settings[:opaque], &settings[:proc]

      expect(subject.auth).to eq(settings.merge(realm: 'super_secret'))
      expect(subject.auth.object_id).not_to eq(first_settings.object_id)
    end
  end

  describe '.http_basic' do
    it 'stets auth parameters' do
      subject.http_basic realm: 'my_realm', &settings[:proc]
      expect(subject.auth).to eq(realm: 'my_realm', type: :http_basic, proc: block)
    end
  end

  describe '.http_digest' do
    it 'stets auth parameters' do
      subject.http_digest realm: 'my_realm', opaque: 'my_opaque', &settings[:proc]
      expect(subject.auth).to eq(realm: 'my_realm', type: :http_digest, proc: block, opaque: 'my_opaque')
    end
  end
end
