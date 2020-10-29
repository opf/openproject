RSpec.describe Airbrake::Filters::ExceptionAttributesFilter do
  describe "#call" do
    let(:notice) { Airbrake::Notice.new(ex) }

    context "when #to_airbrake returns a non-Hash object" do
      let(:ex) do
        Class.new(AirbrakeTestError) do
          def to_airbrake
            Object.new
          end
        end.new
      end

      it "doesn't raise" do
        expect { subject.call(notice) }.not_to raise_error
        expect(notice[:params]).to be_empty
      end
    end

    context "when #to_airbrake errors out" do
      let(:ex) do
        Class.new(AirbrakeTestError) do
          def to_airbrake
            1 / 0
          end
        end.new
      end

      it "doesn't raise" do
        expect { subject.call(notice) }.not_to raise_error
        expect(notice[:params]).to be_empty
      end
    end

    context "when #to_airbrake returns a hash" do
      let(:ex) do
        Class.new(AirbrakeTestError) do
          def to_airbrake
            { params: { foo: '1' } }
          end
        end.new
      end

      it "merges parameters with the notice" do
        subject.call(notice)
        expect(notice[:params]).to eq(foo: '1')
      end
    end
  end
end
