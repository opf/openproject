require "spec_helper"
require "services/base_services/behaves_like_create_service"

RSpec.describe Bim::IfcModels::CreateService do
  it_behaves_like "BaseServices create service" do
    let(:model_class) { Bim::IfcModels::IfcModel }
    let(:factory) { :ifc_model }
    let(:conversion_job) do
      double("ifc_conversion_job").tap do |job|
        allow(job).to receive(:perform_later)

        stub_const("Bim::IfcModels::IfcConversionJob", job)
      end
    end

    it "queues a conversion job" do
      expect(conversion_job)
        .to(receive(:perform_later))
        .with(model_instance)

      subject
    end

    context "if the SetAttributeService is unsuccessful" do
      let(:set_attributes_success) { false }

      it "queues no conversion job" do
        expect(conversion_job).not_to receive(:perform_later)

        subject
      end
    end

    context "when the model is invalid" do
      let(:model_save_result) { false }

      it "queues no conversion job" do
        expect(conversion_job).not_to receive(:perform_later)

        subject
      end
    end
  end
end
