require 'spec_helper'

RSpec.describe Dry::Equalizer do
  let(:name)   { 'User'          }
  let(:klass)  { ::Class.new     }

  context 'with no keys' do
    subject { Dry::Equalizer() }

    before do
      # specify the class #name method
      allow(klass).to receive(:name).and_return(name)
      klass.include(subject)
    end

    let(:instance) { klass.new }

    it { should be_instance_of(described_class) }

    it { should be_frozen }

    it 'defines #hash and #inspect methods dynamically' do
      expect(subject.public_instance_methods(false).map(&:to_s).sort)
        .to eql(%w[hash inspect])
    end

    describe '#eql?' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance.eql?(other)).to be(true) }
      end

      context 'when the objects are different' do
        let(:other) { double('other') }

        it { expect(instance.eql?(other)).to be(false) }
      end
    end

    describe '#==' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance == other).to be(true) }
      end

      context 'when the objects are different' do
        let(:other) { double('other') }

        it { expect(instance == other).to be(false) }
      end
    end

    describe '#hash' do
      it 'has the expected arity' do
        expect(klass.instance_method(:hash).arity).to be(0)
      end

      it { expect(instance.hash).to eql([klass].hash) }
    end

    describe '#inspect' do
      it 'has the expected arity' do
        expect(klass.instance_method(:inspect).arity).to be(0)
      end

      it { expect(instance.inspect).to eql('#<User>') }
    end
  end

  context 'with keys' do
    subject { Dry::Equalizer(*keys) }

    let(:keys)       { %i[firstname lastname].freeze  }
    let(:firstname)  { 'John'                         }
    let(:lastname)   { 'Doe'                          }
    let(:instance)   { klass.new(firstname, lastname) }

    let(:klass) do
      ::Class.new do
        attr_reader :firstname, :lastname
        attr_writer :firstname
        private :firstname, :lastname

        def initialize(firstname, lastname)
          @firstname = firstname
          @lastname = lastname
        end
      end
    end

    before do
      # specify the class #inspect method
      allow(klass).to receive_messages(name: nil, inspect: name)
      klass.include(subject)
    end

    it { should be_instance_of(described_class) }

    it { should be_frozen }

    it 'defines #hash and #inspect methods dynamically' do
      expect(subject.public_instance_methods(false).map(&:to_s).sort)
        .to eql(%w[hash inspect])
    end

    describe '#eql?' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance.eql?(other)).to be(true) }
      end

      context 'when the objects are different' do
        let(:other) { double('other') }

        it { expect(instance.eql?(other)).to be(false) }
      end
    end

    describe '#==' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance == other).to be(true) }
      end

      context 'when the objects are different type' do
        let(:other) { klass.new('Foo', 'Bar') }

        it { expect(instance == other).to be(false) }
      end

      context 'when the objects are from different type' do
        let(:other) { double('other') }

        it { expect(instance == other).to be(false) }
      end
    end

    describe '#hash' do
      it 'returns the expected hash' do
        expect(instance.hash)
          .to eql([firstname, lastname, klass].hash)
      end
    end

    describe '#inspect' do
      it 'returns the expected string' do
        expect(instance.inspect)
          .to eql('#<User firstname="John" lastname="Doe">')
      end
    end

    context 'when immutable' do
      describe '#hash' do

        subject { Dry::Equalizer(*keys, immutable: true) }

        it 'returns memoized hash' do
          expect { instance.firstname = 'Changed' }.not_to(change { instance.hash })
        end
        
        context 'when frozen' do
          it 'returns memoized hash' do
            instance.freeze

            expect(instance.hash)
              .to eql([firstname, lastname, klass].hash)
          end
        end
      end
    end
  end

  context 'with duplicate keys' do
    subject { Dry::Equalizer(*keys) }

    let(:keys)       { %i[firstname firstname lastname].freeze  }
    let(:firstname)  { 'John'                                   }
    let(:lastname)   { 'Doe'                                    }
    let(:instance)   { klass.new(firstname, lastname)           }

    let(:klass) do
      ::Class.new do
        attr_reader :firstname, :lastname
        private :firstname, :lastname

        def initialize(firstname, lastname)
          @firstname = firstname
          @lastname = lastname
        end
      end
    end

    before do
      # specify the class #inspect method
      allow(klass).to receive_messages(name: nil, inspect: name)
      klass.include(subject)
    end

    it { should be_instance_of(described_class) }

    it { should be_frozen }

    describe '#inspect' do
      it 'returns the expected string' do
        expect(instance.inspect)
          .to eql('#<User firstname="John" lastname="Doe">')
      end
    end
  end

  context 'with options' do
    context 'w/o inspect' do
      subject { Dry::Equalizer(*keys, inspect: false) }

      let(:keys)       { %i[firstname lastname].freeze  }
      let(:firstname)  { 'John'                         }
      let(:lastname)   { 'Doe'                          }
      let(:instance)   { klass.new(firstname, lastname) }

      let(:klass) do
        ::Struct.new(:firstname, :lastname)
      end

      before { klass.include(subject) }

      describe '#inspect' do
        it 'returns the default string' do
          expect(instance.inspect).to eql('#<struct firstname="John", lastname="Doe">')
          expect(instance.to_s).to eql('#<struct firstname="John", lastname="Doe">')
        end
      end
    end
  end
end
