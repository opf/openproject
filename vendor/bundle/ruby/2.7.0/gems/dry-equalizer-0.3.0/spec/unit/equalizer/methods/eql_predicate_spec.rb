require 'spec_helper'

RSpec.describe Dry::Equalizer::Methods, '#eql?' do
  subject { object.eql?(other) }

  let(:object) { described_class.new(true) }

  let(:described_class) do
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
      should eql(other.eql?(object))
    end
  end

  context 'with an equivalent object' do
    let(:other) { object.dup }

    it { should be(true) }

    it 'is symmetric' do
      should eql(other.eql?(object))
    end
  end

  context 'with an equivalent object of a subclass' do
    let(:other) { Class.new(described_class).new(true) }

    it { should be(false) }

    it 'is symmetric' do
      should eql(other.eql?(object))
    end
  end

  context 'with a different object' do
    let(:other) { described_class.new(false) }

    it { should be(false) }

    it 'is symmetric' do
      should eql(other.eql?(object))
    end
  end
end
