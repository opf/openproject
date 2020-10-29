# frozen_string_literal: true

require 'spec_helper'

describe Grape::Middleware::Stack do
  module StackSpec
    class FooMiddleware; end
    class BarMiddleware; end
    class BlockMiddleware
      attr_reader :block
      def initialize(&block)
        @block = block
      end
    end
  end

  let(:proc) { ->() {} }
  let(:others) { [[:use, StackSpec::BarMiddleware], [:insert_before, StackSpec::BarMiddleware, StackSpec::BlockMiddleware, proc]] }

  subject { Grape::Middleware::Stack.new }

  before do
    subject.use StackSpec::FooMiddleware
  end

  describe '#use' do
    it 'pushes a middleware class onto the stack' do
      expect { subject.use StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject.last).to eq(StackSpec::BarMiddleware)
    end

    it 'pushes a middleware class with arguments onto the stack' do
      expect { subject.use StackSpec::BarMiddleware, false, my_arg: 42 }
        .to change { subject.size }.by(1)
      expect(subject.last).to eq(StackSpec::BarMiddleware)
      expect(subject.last.args).to eq([false, { my_arg: 42 }])
    end

    it 'pushes a middleware class with block arguments onto the stack' do
      expect { subject.use StackSpec::BlockMiddleware, &proc }
        .to change { subject.size }.by(1)
      expect(subject.last).to eq(StackSpec::BlockMiddleware)
      expect(subject.last.args).to eq([])
      expect(subject.last.block).to eq(proc)
    end
  end

  describe '#insert' do
    it 'inserts a middleware class at the integer index' do
      expect { subject.insert 0, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject[0]).to eq(StackSpec::BarMiddleware)
      expect(subject[1]).to eq(StackSpec::FooMiddleware)
    end
  end

  describe '#insert_before' do
    it 'inserts a middleware before another middleware class' do
      expect { subject.insert_before StackSpec::FooMiddleware, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject[0]).to eq(StackSpec::BarMiddleware)
      expect(subject[1]).to eq(StackSpec::FooMiddleware)
    end

    it 'inserts a middleware before an anonymous class given by its superclass' do
      subject.use Class.new(StackSpec::BlockMiddleware)

      expect { subject.insert_before StackSpec::BlockMiddleware, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)

      expect(subject[1]).to eq(StackSpec::BarMiddleware)
      expect(subject[2]).to eq(StackSpec::BlockMiddleware)
    end

    it 'raises an error on an invalid index' do
      expect { subject.insert_before StackSpec::BlockMiddleware, StackSpec::BarMiddleware }
        .to raise_error(RuntimeError, 'No such middleware to insert before: StackSpec::BlockMiddleware')
    end
  end

  describe '#insert_after' do
    it 'inserts a middleware after another middleware class' do
      expect { subject.insert_after StackSpec::FooMiddleware, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)
      expect(subject[1]).to eq(StackSpec::BarMiddleware)
      expect(subject[0]).to eq(StackSpec::FooMiddleware)
    end

    it 'inserts a middleware after an anonymous class given by its superclass' do
      subject.use Class.new(StackSpec::BlockMiddleware)

      expect { subject.insert_after StackSpec::BlockMiddleware, StackSpec::BarMiddleware }
        .to change { subject.size }.by(1)

      expect(subject[1]).to eq(StackSpec::BlockMiddleware)
      expect(subject[2]).to eq(StackSpec::BarMiddleware)
    end

    it 'raises an error on an invalid index' do
      expect { subject.insert_after StackSpec::BlockMiddleware, StackSpec::BarMiddleware }
        .to raise_error(RuntimeError, 'No such middleware to insert after: StackSpec::BlockMiddleware')
    end
  end

  describe '#merge_with' do
    it 'applies a collection of operations and middlewares' do
      expect { subject.merge_with(others) }
        .to change { subject.size }.by(2)
      expect(subject[0]).to eq(StackSpec::FooMiddleware)
      expect(subject[1]).to eq(StackSpec::BlockMiddleware)
      expect(subject[2]).to eq(StackSpec::BarMiddleware)
    end

    context 'middleware spec with proc declaration exists' do
      let(:middleware_spec_with_proc) { [:use, StackSpec::FooMiddleware, proc] }

      it 'properly forwards spec arguments' do
        expect(subject).to receive(:use).with(StackSpec::FooMiddleware)
        subject.merge_with([middleware_spec_with_proc])
      end
    end
  end

  describe '#build' do
    it 'returns a rack builder instance' do
      expect(subject.build).to be_instance_of(Rack::Builder)
    end

    context 'when @others are present' do
      let(:others) { [[:insert_after, Grape::Middleware::Formatter, StackSpec::BarMiddleware]] }

      it 'applies the middleware specs stored in @others' do
        subject.concat others
        subject.use Grape::Middleware::Formatter
        subject.build
        expect(subject[0]).to eq StackSpec::FooMiddleware
        expect(subject[1]).to eq Grape::Middleware::Formatter
        expect(subject[2]).to eq StackSpec::BarMiddleware
      end
    end
  end

  describe '#concat' do
    it 'adds non :use specs to @others' do
      expect { subject.concat others }.to change(subject, :others).from([]).to([[others.last]])
    end

    it 'calls +merge_with+ with the :use specs' do
      expect(subject).to receive(:merge_with).with [[:use, StackSpec::BarMiddleware]]
      subject.concat others
    end
  end
end
