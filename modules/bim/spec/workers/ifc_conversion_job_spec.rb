require "spec_helper"

RSpec.describe Bim::IfcModels::IfcConversionJob, type: :job do
  let(:model) { build(:ifc_model) }

  subject { described_class.perform_now(model) }

  it "calls the conversion service" do
    expect(Bim::IfcModels::ViewConverterService)
      .to receive_message_chain(:new, :call)
      .and_return ServiceResult.success

    expect { subject }.not_to raise_error
  end
end
