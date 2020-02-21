require 'spec_helper'

describe Bim::IfcModels::IfcConversionJob, type: :job do
  let(:model) { FactoryBot.build :ifc_model }
  subject { described_class.perform_now(model) }

  it 'calls the conversion service' do
    expect(::Bim::IfcModels::ViewConverterService)
      .to receive_message_chain(:new, :call)
      .and_return ServiceResult.new success: true

    expect { subject }.not_to raise_error
  end
end
