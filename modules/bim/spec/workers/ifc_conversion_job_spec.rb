require 'spec_helper'

describe Bim::IfcModels::IfcConversionJob, type: :job do
  let(:model) { FactoryBot.build :ifc_model }
  let(:instance) { described_class.new }
  let(:attachment_double) { instance_double(Attachment) }
  let(:prepared) { false }
  let(:diskfile) { 'foo' }

  subject { instance.perform(model) }

  before do
    allow(model).to receive(:ifc_attachment).and_return(attachment_double)
    allow(attachment_double).to receive(:diskfile).and_return diskfile
    allow(attachment_double).to receive(:prepared?).and_return prepared
  end

  it 'calls the conversion service' do
    expect(::Bim::IfcModels::ViewConverterService)
      .to receive_message_chain(:new, :call)
            .and_return ServiceResult.new success: true

    expect { subject }.not_to raise_error
  end

  shared_examples 'will reschedule' do
    it 'will reschedule the job' do
      allow(instance).to receive(:retry_job)

      subject

      expect(instance).to have_received(:retry_job).with(wait: 1.minute)
    end
  end

  context 'when the diskfile is empty' do
    let(:diskfile) { nil }

    it_behaves_like 'will reschedule'
  end

  context 'when the attachment is not persisted' do
    let(:prepared) { true }

    it_behaves_like 'will reschedule'
  end
end
