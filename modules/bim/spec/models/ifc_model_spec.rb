require 'spec_helper'

describe ::Bim::IfcModels::IfcModel, type: :model do
  subject { described_class.new params }
  let(:params) { { title: 'foo', is_default: true } }

  describe 'converted?' do
    let(:attachment) { FactoryBot.build :attachment }
    it 'is converted when xkt and metadata attachments are present' do
      expect(subject).not_to be_converted

      allow(subject).to receive(:xkt_attachment).and_return(attachment)
      allow(subject).to receive(:metadata_attachment).and_return(attachment)

      expect(subject).to be_converted
    end
  end

  describe 'ifc_attachment=' do
    subject { FactoryBot.create :ifc_model_minimal_converted, project: FactoryBot.create(:project) }
    let(:ifc_attachment) { subject.ifc_attachment }
    let(:new_attachment) do
      FileHelpers.mock_uploaded_file name: "model.ifc", content_type: 'application/binary', binary: true
    end

    it 'replaces the previous attachment' do
      expect(ifc_attachment).to be_present
      expect(subject.xkt_attachment).to be_present
      expect(subject.metadata_attachment).to be_present
      expect(subject).to be_converted

      subject.ifc_attachment = new_attachment
      expect { ifc_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(subject.ifc_attachment).not_to eq ifc_attachment
      expect(subject.ifc_attachment).not_to be_present
      expect(subject.xkt_attachment).not_to be_present
      expect(subject).not_to be_converted
    end
  end
end
