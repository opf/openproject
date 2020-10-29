RSpec.describe Airbrake::TDigest do
  describe "byte serialization" do
    it "loads serialized data" do
      subject.push(60, 100)
      10.times { subject.push(rand * 100) }
      bytes = subject.as_bytes
      new_tdigest = described_class.from_bytes(bytes)
      expect(new_tdigest.percentile(0.9)).to eq(subject.percentile(0.9))
      expect(new_tdigest.as_bytes).to eq(bytes)
    end

    it "handles zero size" do
      bytes = subject.as_bytes
      expect(described_class.from_bytes(bytes).size).to be_zero
    end

    it "preserves compression" do
      td = described_class.new(0.001)
      bytes = td.as_bytes
      new_tdigest = described_class.from_bytes(bytes)
      expect(new_tdigest.compression).to eq(td.compression)
    end
  end

  describe "small byte serialization" do
    it "loads serialized data" do
      10.times { subject.push(10) }
      bytes = subject.as_small_bytes
      new_tdigest = described_class.from_bytes(bytes)
      # Expect some rounding error due to compression
      expect(new_tdigest.percentile(0.9).round(5)).to eq(
        subject.percentile(0.9).round(5),
      )
      expect(new_tdigest.as_small_bytes).to eq(bytes)
    end

    it "handles zero size" do
      bytes = subject.as_small_bytes
      expect(described_class.from_bytes(bytes).size).to be_zero
    end
  end

  describe "JSON serialization" do
    it "loads serialized data" do
      subject.push(60, 100)
      json = subject.as_json
      new_tdigest = described_class.from_json(json)
      expect(new_tdigest.percentile(0.9)).to eq(subject.percentile(0.9))
    end
  end

  describe "#percentile" do
    it "returns nil if empty" do
      expect(subject.percentile(0.90)).to be_nil # This should not crash
    end

    it "raises ArgumentError of input not between 0 and 1" do
      expect { subject.percentile(1.1) }.to raise_error(ArgumentError)
    end

    describe "with only single value" do
      it "returns the value" do
        subject.push(60, 100)
        expect(subject.percentile(0.90)).to eq(60)
      end

      it "returns 0 for all percentiles when only 0 present" do
        subject.push(0)
        expect(subject.percentile([0.0, 0.5, 1.0])).to eq([0, 0, 0])
      end
    end

    describe "with alot of uniformly distributed points" do
      it "has minimal error" do
        seed = srand(1234) # Makes the values a proper fixture
        N = 100_000
        maxerr = 0
        values = Array.new(N).map { rand }
        srand(seed)

        subject.push(values)
        subject.compress!

        0.step(1, 0.1).each do |i|
          q = subject.percentile(i)
          maxerr = [maxerr, (i - q).abs].max
        end

        expect(maxerr).to be < 0.01
      end
    end
  end

  describe "#push" do
    it "calls _cumulate so won't crash because of uninitialized mean_cumn" do
      subject.push(
        [
          125000000.0,
          104166666.66666666,
          135416666.66666666,
          104166666.66666666,
          104166666.66666666,
          93750000.0,
          125000000.0,
          62500000.0,
          114583333.33333333,
          156250000.0,
          124909090.90909092,
          104090909.0909091,
          135318181.81818184,
          104090909.0909091,
          104090909.0909091,
          93681818.18181819,
          124909090.90909092,
          62454545.45454546,
          114500000.00000001,
          156136363.63636366,
          123567567.56756756,
          102972972.97297296,
          133864864.86486486,
          102972972.97297296,
          102972972.97297296,
          92675675.67567568,
          123567567.56756756,
          61783783.78378378,
          113270270.27027026,
          154459459.45945945,
          123829787.23404256,
          103191489.36170213,
        ],
      )
    end

    it "does not blow up if data comes in sorted" do
      subject.push(0..10_000)
      expect(subject.centroids.size).to be < 5_000
      subject.compress!
      expect(subject.centroids.size).to be < 1_000
    end
  end

  describe "#size" do
    it "reports the number of observations" do
      n = 10_000
      n.times { subject.push(rand) }
      subject.compress!
      expect(subject.size).to eq(n)
    end
  end

  describe "#+" do
    it "works with empty tdigests" do
      other = described_class.new(0.001, 50, 1.2)
      expect((subject + other).centroids.size).to eq(0)
    end

    describe "adding two tdigests" do
      before do
        @other = described_class.new(0.001, 50, 1.2)
        [subject, @other].each do |td|
          td.push(60, 100)
          10.times { td.push(rand * 100) }
        end
      end

      it "has the parameters of the left argument (the calling tdigest)" do
        new_tdigest = subject + @other
        expect(new_tdigest.instance_variable_get(:@delta)).to eq(
          subject.instance_variable_get(:@delta),
        )
        expect(new_tdigest.instance_variable_get(:@k)).to eq(
          subject.instance_variable_get(:@k),
        )
        expect(new_tdigest.instance_variable_get(:@cx)).to eq(
          subject.instance_variable_get(:@cx),
        )
      end

      it "returns a tdigest with less than or equal centroids" do
        new_tdigest = subject + @other
        expect(new_tdigest.centroids.size)
          .to be <= subject.centroids.size + @other.centroids.size
      end

      it "has the size of the two digests combined" do
        new_tdigest = subject + @other
        expect(new_tdigest.size).to eq(subject.size + @other.size)
      end
    end
  end

  describe "#merge!" do
    it "works with empty tdigests" do
      other = described_class.new(0.001, 50, 1.2)
      subject.merge!(other)
      expect(subject.centroids.size).to be_zero
    end

    describe "with populated tdigests" do
      before do
        @other = described_class.new(0.001, 50, 1.2)
        [subject, @other].each do |td|
          td.push(60, 100)
          10.times { td.push(rand * 100) }
        end
      end

      it "has the parameters of the calling tdigest" do
        vars = %i[@delta @k @cx]
        expected = Hash[vars.map { |v| [v, subject.instance_variable_get(v)] }]
        subject.merge!(@other)
        vars.each do |v|
          expect(subject.instance_variable_get(v)).to eq(expected[v])
        end
      end

      it "returns a tdigest with less than or equal centroids" do
        combined_size = subject.centroids.size + @other.centroids.size
        subject.merge!(@other)
        expect(subject.centroids.size).to be <= combined_size
      end

      it "has the size of the two digests combined" do
        combined_size = subject.size + @other.size
        subject.merge!(@other)
        expect(subject.size).to eq(combined_size)
      end
    end
  end
end
