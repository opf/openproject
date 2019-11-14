require 'spec_helper'

describe IFCModels::ViewConverterService do
  let(:model) { FactoryBot.build :ifc_model }
  subject { described_class.new }

  shared_context 'available pipeline commands' do |available|
    before do
      # Mock the call to Open3 to test available commands
      allow(Open3)
        .to(receive(:capture2e))
        .with('which', any_args)
        .and_wrap_original do |_, *args|

        matches =
           if available.is_a?(Array)
             available.include?(args[1])
           else
             available
           end

        result = OpenStruct.new(exitstatus: matches ? 0 : 1)
        ["irrelevant output", result]
      end
    end
  end

  describe '#available_commands' do
    context 'with only one available command' do
      include_context 'available pipeline commands', %w[IfcConvert]

      it 'is not available' do
        expect(subject).not_to be_available
      end
    end

    context 'with all available commands' do
      include_context 'available pipeline commands', described_class::PIPELINE_COMMANDS

      it 'is available' do
        expect(subject).to be_available
      end
    end
  end

  describe '#call' do

    context 'if not available?' do
      include_context 'available pipeline commands', false

      it 'returns an error' do
        expect(subject).not_to be_available
        result = subject.call(model)
        expect(result.errors[:base].first).to include 'The following IFC converter commands are missing'
      end
    end

    context 'if available' do
      before do
        allow(subject).to receive(:available?).and_return true
      end

      it 'calls the conversion and returns save result' do
        expect(subject)
          .to(receive(:perform_conversion!))

        expect(model)
          .to(receive(:save))
          .and_return(true)

        expect(subject.call(model)).to be_success
      end

      it 'calls the conversion and returns error' do
        expect(subject)
          .to(receive(:perform_conversion!))

        expect(model)
          .to(receive(:save))
          .and_return(false)

        expect(subject.call(model)).not_to be_success
      end
    end
  end
end