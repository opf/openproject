require 'helper'

describe Delayed::Lifecycle do
  let(:lifecycle) { Delayed::Lifecycle.new }
  let(:callback) { lambda { |*_args| } }
  let(:arguments) { [1] }
  let(:behavior) { double(Object, :before! => nil, :after! => nil, :inside! => nil) }
  let(:wrapped_block) { proc { behavior.inside! } }

  describe 'before callbacks' do
    before(:each) do
      lifecycle.before(:execute, &callback)
    end

    it 'executes before wrapped block' do
      expect(callback).to receive(:call).with(*arguments).ordered
      expect(behavior).to receive(:inside!).ordered
      lifecycle.run_callbacks :execute, *arguments, &wrapped_block
    end
  end

  describe 'after callbacks' do
    before(:each) do
      lifecycle.after(:execute, &callback)
    end

    it 'executes after wrapped block' do
      expect(behavior).to receive(:inside!).ordered
      expect(callback).to receive(:call).with(*arguments).ordered
      lifecycle.run_callbacks :execute, *arguments, &wrapped_block
    end
  end

  describe 'around callbacks' do
    before(:each) do
      lifecycle.around(:execute) do |*args, &block|
        behavior.before!
        block.call(*args)
        behavior.after!
      end
    end

    it 'wraps a block' do
      expect(behavior).to receive(:before!).ordered
      expect(behavior).to receive(:inside!).ordered
      expect(behavior).to receive(:after!).ordered
      lifecycle.run_callbacks :execute, *arguments, &wrapped_block
    end

    it 'executes multiple callbacks in order' do
      expect(behavior).to receive(:one).ordered
      expect(behavior).to receive(:two).ordered
      expect(behavior).to receive(:three).ordered

      lifecycle.around(:execute) do |*args, &block|
        behavior.one
        block.call(*args)
      end
      lifecycle.around(:execute) do |*args, &block|
        behavior.two
        block.call(*args)
      end
      lifecycle.around(:execute) do |*args, &block|
        behavior.three
        block.call(*args)
      end
      lifecycle.run_callbacks(:execute, *arguments, &wrapped_block)
    end
  end

  it 'raises if callback is executed with wrong number of parameters' do
    lifecycle.before(:execute, &callback)
    expect { lifecycle.run_callbacks(:execute, 1, 2, 3) {} }.to raise_error(ArgumentError, /1 parameter/)
  end
end
