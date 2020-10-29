# frozen_string_literal: true

require 'spec_helper'

describe Grape::Parser do
  subject { described_class }

  describe '.builtin_parsers' do
    it 'returns an instance of Hash' do
      expect(subject.builtin_parsers).to be_an_instance_of(Hash)
    end

    it 'includes json and xml parsers by default' do
      expect(subject.builtin_parsers).to include(json: Grape::Parser::Json, xml: Grape::Parser::Xml)
    end
  end

  describe '.parsers' do
    it 'returns an instance of Hash' do
      expect(subject.parsers(**{})).to be_an_instance_of(Hash)
    end

    it 'includes built-in parsers' do
      expect(subject.parsers(**{})).to include(subject.builtin_parsers)
    end

    context 'with :parsers option' do
      let(:parsers) { { customized: Class.new } }
      it 'includes passed :parsers values' do
        expect(subject.parsers(parsers: parsers)).to include(parsers)
      end
    end

    context 'with added parser by using `register` keyword' do
      let(:added_parser) { Class.new }
      before { subject.register :added, added_parser }
      it 'includes added parser' do
        expect(subject.parsers(**{})).to include(added: added_parser)
      end
    end
  end

  describe '.parser_for' do
    let(:options) { {} }

    it 'calls .parsers' do
      expect(subject).to receive(:parsers).with(any_args).and_return(subject.builtin_parsers)
      subject.parser_for(:json, **options)
    end

    it 'returns parser correctly' do
      expect(subject.parser_for(:json)).to eq(Grape::Parser::Json)
    end

    context 'when parser is available' do
      before { subject.register :customized_json, Grape::Parser::Json }
      it 'returns registered parser if available' do
        expect(subject.parser_for(:customized_json)).to eq(Grape::Parser::Json)
      end
    end

    context 'when parser is an instance of Symbol' do
      before do
        allow(subject).to receive(:foo).and_return(:bar)
        subject.register :foo, :foo
      end

      it 'returns an instance of Method' do
        expect(subject.parser_for(:foo)).to be_an_instance_of(Method)
      end

      it 'returns object which can be called' do
        method = subject.parser_for(:foo)
        expect(method.call).to eq(:bar)
      end
    end

    context 'when parser does not exist' do
      it 'returns nil' do
        expect(subject.parser_for(:undefined)).to be_nil
      end
    end
  end
end
