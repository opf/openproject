require 'spec_helper'

RSpec.describe Dry::Equalizer::Methods, '#==' do
  subject { object == other }

  let(:object)          { described_class.new(true) }
  let(:described_class) { Class.new(super_class)    }

  let(:super_class) do
    Class.new do
      include Dry::Equalizer::Methods

      attr_reader :boolean

      def initialize(boolean)
        @boolean = boolean
      end

      def cmp?(comparator, other)
        boolean.send(comparator, other.boolean)
      end
    end
  end

  context 'with the same object' do
    let(:other) { object }

    it { should be(true) }

    it 'is symmetric' do
      should eql(other == object)
    end
  end

  context 'with an equivalent object' do
    let(:other) { object.dup }

    it { should be(true) }

    it 'is symmetric' do
      should eql(other == object)
    end
  end

  context 'with a subclass instance having equivalent obervable state' do
    let(:other) { Class.new(described_class).new(true) }

    it { should be(true) }

    it 'is not symmetric' do
      # the subclass instance should maintain substitutability with the object
      # (in the LSP sense) the reverse is not true.
      should_not eql(other == object)
    end
  end

  context 'with a superclass instance having equivalent observable state' do
    let(:other) { super_class.new(true) }

    it { should be(false) }

    it 'is not symmetric' do
      should_not eql(other == object)
    end
  end

  context 'with an object of another class' do
    let(:other) { Class.new.new }

    it { should be(false) }

    it 'is symmetric' do
      should eql(other == object)
    end
  end

  context 'with a different object' do
    let(:other) { described_class.new(false) }

    it { should be(false) }

    it 'is symmetric' do
      should eql(other == object)
    end
  end
end
