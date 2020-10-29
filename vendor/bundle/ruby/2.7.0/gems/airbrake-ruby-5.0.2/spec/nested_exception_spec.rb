RSpec.describe Airbrake::NestedException do
  describe "#as_json" do
    context "given exceptions with backtraces" do
      it "unwinds nested exceptions" do
        begin
          begin
            raise AirbrakeTestError
          rescue AirbrakeTestError
            Ruby21Error.raise_error('bingo')
          end
        rescue Ruby21Error => ex
          nested_exception = described_class.new(ex)
          exceptions = nested_exception.as_json

          expect(exceptions.size).to eq(2)
          expect(exceptions[0][:message]).to eq('bingo')
          expect(exceptions[1][:message]).to eq('App crashed!')
          expect(exceptions[0][:backtrace]).not_to be_empty
          expect(exceptions[1][:backtrace]).not_to be_empty
        end
      end

      it "unwinds no more than 3 nested exceptions" do
        begin
          begin
            raise AirbrakeTestError
          rescue AirbrakeTestError
            begin
              Ruby21Error.raise_error('bongo')
            rescue Ruby21Error
              begin
                Ruby21Error.raise_error('bango')
              rescue Ruby21Error
                Ruby21Error.raise_error('bingo')
              end
            end
          end
        rescue Ruby21Error => ex
          nested_exception = described_class.new(ex)
          exceptions = nested_exception.as_json

          expect(exceptions.size).to eq(3)
          expect(exceptions[0][:message]).to eq('bingo')
          expect(exceptions[1][:message]).to eq('bango')
          expect(exceptions[2][:message]).to eq('bongo')
          expect(exceptions[0][:backtrace]).not_to be_empty
          expect(exceptions[1][:backtrace]).not_to be_empty
        end
      end
    end

    context "given exceptions without backtraces" do
      it "sets backtrace to nil" do
        begin
          begin
            raise AirbrakeTestError
          rescue AirbrakeTestError => ex2
            ex2.set_backtrace([])
            Ruby21Error.raise_error('bingo')
          end
        rescue Ruby21Error => ex1
          ex1.set_backtrace([])
          nested_exception = described_class.new(ex1)
          exceptions = nested_exception.as_json

          expect(exceptions.size).to eq(2)
          expect(exceptions[0][:backtrace]).to be_empty
          expect(exceptions[1][:backtrace]).to be_empty
        end
      end
    end
  end
end
