RSpec.describe Airbrake::TimedTrace do
  describe ".span" do
    it "returns a timed trace" do
      expect(described_class.span('operation') {}).to be_a(described_class)
    end

    it "returns a timed trace with a stopped span" do
      timed_trace = described_class.span('operation') {}
      expect(timed_trace.spans).to match('operation' => be > 0)
    end
  end

  describe "#span" do
    it "captures a span" do
      subject.span('operation') {}
      expect(subject.spans).to match('operation' => be > 0)
    end
  end

  describe "#start_span" do
    context "when called once" do
      it "returns true" do
        expect(subject.start_span('operation')).to eq(true)
      end
    end

    context "when called multiple times" do
      before { subject.start_span('operation') }

      it "returns false" do
        expect(subject.start_span('operation')).to eq(false)
      end
    end

    context "when another span was started" do
      before { subject.start_span('operation') }

      it "returns true" do
        expect(subject.start_span('another operation')).to eq(true)
      end
    end

    context "when #spans was called" do
      before { subject.start_span('operation') }

      it "returns spans with zero values" do
        expect(subject.spans).to eq('operation' => 0.0)
      end
    end
  end

  describe "#stop_span" do
    context "when #start_span wasn't invoked" do
      it "returns false" do
        expect(subject.stop_span('operation')).to eq(false)
      end
    end

    context "when #start_span was invoked" do
      before { subject.start_span('operation') }

      it "returns true" do
        expect(subject.stop_span('operation')).to eq(true)
      end
    end

    context "when multiple spans were started" do
      before do
        subject.start_span('operation')
        subject.start_span('another operation')
      end

      context "and when stopping in LIFO order" do
        it "returns true for all spans" do
          expect(subject.stop_span('another operation')).to eq(true)
          expect(subject.stop_span('operation')).to eq(true)
        end
      end

      context "and when stopping in FIFO order" do
        it "returns true for all spans" do
          expect(subject.stop_span('operation')).to eq(true)
          expect(subject.stop_span('another operation')).to eq(true)
        end
      end
    end
  end

  describe "#spans" do
    context "when no spans were captured" do
      it "returns an empty hash" do
        expect(subject.spans).to eq({})
      end
    end

    context "when a span was captured" do
      before do
        subject.start_span('operation')
        subject.stop_span('operation')
      end

      it "returns a Hash with the corresponding span" do
        subject.stop_span('operation')
        expect(subject.spans).to match('operation' => be > 0)
      end
    end

    context "when multiple spans were captured" do
      before do
        subject.start_span('operation')
        subject.stop_span('operation')

        subject.start_span('another operation')
        subject.stop_span('another operation')
      end

      it "returns a Hash with all spans" do
        expect(subject.spans).to match(
          'operation' => be > 0,
          'another operation' => be > 0,
        )
      end
    end
  end
end
