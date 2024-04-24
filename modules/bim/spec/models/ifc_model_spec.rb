require "spec_helper"

RSpec.describe Bim::IfcModels::IfcModel do
  subject { described_class.new params }

  let(:params) { { title: "foo", is_default: true } }

  describe "converted?" do
    let(:attachment) { build(:attachment) }

    it "is converted when the xkt attachment is present" do
      expect(subject).not_to be_converted

      allow(subject).to receive(:xkt_attachment).and_return(attachment)

      expect(subject).to be_converted
    end
  end

  describe "ifc_attachment=" do
    let(:project) { create(:project, enabled_module_names: %i[bim]) }
    let(:ifc_attachment) { subject.ifc_attachment }
    let(:new_attachment) do
      FileHelpers.mock_uploaded_file name: "model.ifc", content_type: "application/binary", binary: true
    end

    subject { create(:ifc_model_minimal_converted, project:) }

    current_user do
      create(:user,
             member_with_permissions: { project => %i[manage_ifc_models] })
    end

    it "replaces the previous attachment" do
      expect(ifc_attachment).to be_present
      expect(subject.xkt_attachment).to be_present
      expect(subject).to be_converted

      subject.ifc_attachment = new_attachment
      expect { ifc_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(subject.ifc_attachment).not_to eq ifc_attachment
      expect(subject.ifc_attachment).to be_present
      expect(subject.xkt_attachment).not_to be_present
      expect(subject).not_to be_converted
    end
  end
end
