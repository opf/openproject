RSpec.describe Airbrake::Truncator do
  def multiply_by_2_max_len(chr)
    chr * 2 * max_len
  end

  describe "#truncate" do
    let(:max_size) { 3 }
    let(:truncated) { '[Truncated]' }
    let(:max_len) { max_size + truncated.length }

    subject { described_class.new(max_size).truncate(object) }

    context "given a frozen string" do
      let(:object) { multiply_by_2_max_len('a') }

      it "returns a new truncated frozen string" do
        expect(subject.length).to eq(max_len)
        expect(subject).to be_frozen
      end
    end

    context "given a frozen hash of strings" do
      let(:object) do
        {
          banana: multiply_by_2_max_len('a'),
          kiwi: multiply_by_2_max_len('b'),
          strawberry: 'c',
          shrimp: 'd',
        }.freeze
      end

      it "returns a new truncated frozen hash" do
        expect(subject.size).to eq(max_size)
        expect(subject).to be_frozen

        expect(subject).to eq(
          banana: 'aaa[Truncated]', kiwi: 'bbb[Truncated]', strawberry: 'c',
        )
        expect(subject[:banana]).to be_frozen
        expect(subject[:kiwi]).to be_frozen
        expect(subject[:strawberry]).not_to be_frozen
      end
    end

    context "given a frozen array of strings" do
      let(:object) do
        [
          multiply_by_2_max_len('a'),
          'b',
          multiply_by_2_max_len('c'),
          'd',
        ].freeze
      end

      it "returns a new truncated frozen array" do
        expect(subject.size).to eq(max_size)
        expect(subject).to be_frozen

        expect(subject).to eq(['aaa[Truncated]', 'b', 'ccc[Truncated]'])
        expect(subject[0]).to be_frozen
        expect(subject[1]).not_to be_frozen
        expect(subject[2]).to be_frozen
      end
    end

    context "given a frozen set of strings" do
      let(:object) do
        Set.new([
          multiply_by_2_max_len('a'),
          'b',
          multiply_by_2_max_len('c'),
          'd',
        ]).freeze
      end

      it "returns a new truncated frozen array" do
        expect(subject.size).to eq(max_size)
        expect(subject).to be_frozen

        expect(subject).to eq(
          Set.new(['aaa[Truncated]', 'b', 'ccc[Truncated]']),
        )
        expect(subject).to be_frozen
      end
    end

    context "given an arbitrary frozen object that responds to #to_json" do
      let(:object) do
        obj = Object.new
        def obj.to_json
          '{"object":"shrimp"}'
        end
        obj.freeze
      end

      it "converts the object to truncated JSON" do
        expect(subject.length).to eq(max_len)
        expect(subject).to be_frozen

        expect(subject).to eq('{"o[Truncated]')
      end
    end

    context "given an arbitrary object that doesn't respond to #to_json" do
      let(:object) do
        obj = Object.new
        allow(obj).to receive(:to_json)
          .and_raise(Airbrake::Notice::JSON_EXCEPTIONS.first)
        obj
      end

      it "converts the object to a truncated string" do
        expect(subject.length).to eq(max_len)
        expect(subject).to eq('#<O[Truncated]')
      end
    end

    shared_examples 'self returning objects' do |object|
      it "returns the passed object" do
        expect(described_class.new(max_size).truncate(object)).to eql(object)
      end
    end

    [1, true, false, :symbol, nil].each do |object|
      include_examples 'self returning objects', object
    end

    context "given a recursive array" do
      let(:object) do
        a = %w[aaaaa bb]
        a << a
        a << 'c'
        a
      end

      it "prevents recursion" do
        expect(subject).to eq(['aaa[Truncated]', 'bb', '[Circular]'])
      end
    end

    context "given a recursive array with recursive hashes" do
      let(:object) do
        a = []
        a << a

        h = {}
        h[:k] = h
        a << h << 'aaaa'
      end

      it "prevents recursion" do
        expect(subject).to eq(['[Circular]', { k: '[Circular]' }, 'aaa[Truncated]'])
        expect(subject).to be_frozen
      end
    end

    context "given a recursive set with recursive arrays" do
      let(:object) do
        s = Set.new
        s << s

        h = {}
        h[:k] = h
        s << h << 'aaaa'
      end

      it "prevents recursion" do
        expect(subject).to eq(
          Set.new(['[Circular]', { k: '[Circular]' }, 'aaa[Truncated]']),
        )
        expect(subject).to be_frozen
      end
    end

    context "given a hash with long strings" do
      let(:object) do
        {
          a: multiply_by_2_max_len('a'),
          b: multiply_by_2_max_len('b'),
          c: { d: multiply_by_2_max_len('d'), e: 'e' },
        }
      end

      it "truncates the long strings" do
        expect(subject).to eq(
          a: 'aaa[Truncated]', b: 'bbb[Truncated]', c: { d: 'ddd[Truncated]', e: 'e' },
        )
        expect(subject).to be_frozen
      end
    end

    context "given a string with valid unicode characters" do
      let(:object) { "€€€€€" }

      it "truncates the string" do
        expect(subject).to eq("€€€[Truncated]")
      end
    end

    context "given an ASCII-8BIT string with invalid characters" do
      let(:object) do
        # Shenanigans to get a bad ASCII-8BIT string. Direct conversion raises error.
        encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
        Base64.decode64(encoded).freeze
      end

      it "converts and truncates the string to UTF-8" do
        expect(subject).to eq("���[Truncated]")
        expect(subject).to be_frozen
      end
    end

    context "given an array with hashes and hash-like objects with identical keys" do
      let(:hashie) { Class.new(Hash) }

      let(:object) do
        {
          errors: [
            { file: 'a' },
            { file: 'a' },
            hashie.new.merge(file: 'bcde'),
          ],
        }
      end

      it "truncates values" do
        expect(subject).to eq(
          errors: [
            { file: 'a' },
            { file: 'a' },
            hashie.new.merge(file: 'bcd[Truncated]'),
          ],
        )
        expect(subject).to be_frozen
      end
    end
  end
end
