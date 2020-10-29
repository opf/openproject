RSpec.describe Dry::Container::Mixin do
  describe 'extended' do
    let(:klass) do
      Class.new { extend Dry::Container::Mixin }
    end
    let(:container) { klass }

    it_behaves_like 'a container'
  end

  describe 'included' do
    let(:klass) do
      Class.new { include Dry::Container::Mixin }
    end
    let(:container) { klass.new }

    it_behaves_like 'a container'

    context 'into a class with a custom .initialize method' do
      let(:klass) do
        Class.new do
          include Dry::Container::Mixin
          def initialize; end
        end
      end

      it 'does not fail on missing member variable' do
        expect { container.register :key, -> {} }.to_not raise_error
      end
    end
  end
end
