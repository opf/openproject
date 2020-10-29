RSpec.describe Airbrake::Promise do
  describe ".then" do
    let(:resolved_with) { [] }
    let(:rejected_with) { [] }

    context "when it is not resolved" do
      it "returns self" do
        expect(subject.then {}).to eq(subject)
      end

      it "doesn't call the resolve callbacks yet" do
        subject.then { resolved_with << 1 }.then { resolved_with << 2 }
        expect(resolved_with).to be_empty
      end
    end

    context "when it is resolved" do
      shared_examples "then specs" do
        it "returns self" do
          expect(subject.then {}).to eq(subject)
        end

        it "yields the resolved value" do
          yielded = nil
          subject.then { |value| yielded = value }
          expect(yielded).to eq('id' => '123')
        end

        it "calls the resolve callbacks" do
          expect(resolved_with).to match_array([1, 2])
        end

        it "doesn't call the reject callbacks" do
          expect(rejected_with).to be_empty
        end
      end

      context "and there are some resolve and reject callbacks in place" do
        before do
          subject.then { resolved_with << 1 }.then { resolved_with << 2 }
          subject.rescue { rejected_with << 1 }.rescue { rejected_with << 2 }
          subject.resolve('id' => '123')
        end

        include_examples "then specs"

        it "registers the resolve callbacks" do
          subject.resolve('id' => '456')
          expect(resolved_with).to match_array([1, 2, 1, 2])
        end
      end

      context "and additional then callbacks are added" do
        before do
          subject.resolve('id' => '123')
          subject.then { resolved_with << 1 }.then { resolved_with << 2 }
        end

        include_examples "then specs"

        it "doesn't register new resolve callbacks" do
          subject.resolve('id' => '456')
          expect(resolved_with).to match_array([1, 2])
        end
      end
    end
  end

  describe ".rescue" do
    let(:resolved_with) { [] }
    let(:rejected_with) { [] }

    context "when it is not rejected" do
      it "returns self" do
        expect(subject.then {}).to eq(subject)
      end

      it "doesn't call the reject callbacks yet" do
        subject.rescue { rejected_with << 1 }.rescue { rejected_with << 2 }
        expect(rejected_with).to be_empty
      end
    end

    context "when it is rejected" do
      shared_examples "rescue specs" do
        it "returns self" do
          expect(subject.rescue {}).to eq(subject)
        end

        it "yields the rejected value" do
          yielded = nil
          subject.rescue { |value| yielded = value }
          expect(yielded).to eq('bingo')
        end

        it "doesn't call the resolve callbacks" do
          expect(resolved_with).to be_empty
        end

        it "calls the reject callbacks" do
          expect(rejected_with).to match_array([1, 2])
        end
      end

      context "and there are some resolve and reject callbacks in place" do
        before do
          subject.then { resolved_with << 1 }.then { resolved_with << 2 }
          subject.rescue { rejected_with << 1 }.rescue { rejected_with << 2 }
          subject.reject('bingo')
        end

        include_examples "rescue specs"

        it "registers the reject callbacks" do
          subject.reject('bingo again')
          expect(rejected_with).to match_array([1, 2, 1, 2])
        end
      end

      context "and additional reject callbacks are added" do
        before do
          subject.reject('bingo')
          subject.rescue { rejected_with << 1 }.rescue { rejected_with << 2 }
        end

        include_examples "rescue specs"

        it "doesn't register new reject callbacks" do
          subject.reject('bingo again')
          expect(rejected_with).to match_array([1, 2])
        end
      end
    end
  end

  describe ".resolve" do
    it "returns self" do
      expect(subject.resolve(1)).to eq(subject)
    end

    it "executes callbacks attached with .then" do
      array = []
      subject.then { |notice_id| array << notice_id }.rescue { array << 999 }

      expect(array.size).to be_zero
      subject.resolve(1)
      expect(array).to match_array([1])
    end
  end

  describe ".reject" do
    it "returns self" do
      expect(subject.reject(1)).to eq(subject)
    end

    it "executes callbacks attached with .rescue" do
      array = []
      subject.then { array << 1 }.rescue { |error| array << error }

      expect(array.size).to be_zero
      subject.reject(999)
      expect(array).to match_array([999])
    end
  end

  describe "#rejected?" do
    context "when it was rejected" do
      before { subject.reject(1) }
      it { is_expected.to be_rejected }
    end

    context "when it wasn't rejected" do
      it { is_expected.not_to be_rejected }
    end

    context "when it was resolved" do
      before { subject.resolve }
      it { is_expected.not_to be_rejected }
    end
  end

  describe "#resolved?" do
    context "when it was resolved" do
      before { subject.resolve }
      it { is_expected.to be_resolved }
    end

    context "when it wasn't resolved" do
      it { is_expected.not_to be_resolved }
    end

    context "when it was rejected" do
      before { subject.reject(1) }
      it { is_expected.not_to be_resolved }
    end
  end
end
