require 'spec_helper'

describe Bim::IfcModels::UpdateService do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    double('contract_class', '<=': true)
  end
  let(:model_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        model: model,
                        contract_class: contract_class)
  end
  let(:call_attributes) { { name: 'Some name', identifier: 'Some identifier' } }
  let(:set_attributes_success) do
    true
  end
  let(:set_attributes_errors) do
    double('set_attributes_errors')
  end
  let(:set_attributes_result) do
    ServiceResult.new result: model,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:model) do
    FactoryBot.build_stubbed(:ifc_model).tap do |m|
      allow(m)
        .to receive(:save)
        .and_return(model_valid)
      allow(m)
        .to receive(:ifc_attachment)
        .and_return(ifc_attachment)
      allow(m)
        .to receive(:attachments)
        .and_return(attachments)
    end
  end
  let!(:set_attributes_service) do
    service = double('set_attributes_service_instance')

    allow(Bim::IfcModels::SetAttributesService)
      .to receive(:new)
      .with(user: user,
            model: model,
            contract_class: contract_class,
            contract_options: {})
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(set_attributes_result)
  end
  let(:conversion_job) do
    double('ifc_conversion_job').tap do |job|
      allow(job)
        .to receive(:perform_later)

      stub_const('Bim::IfcModels::IfcConversionJob', job)
    end
  end
  let(:ifc_attachment) { FactoryBot.build_stubbed(:attachment) }
  let(:other_attachment) do
    FactoryBot.build_stubbed(:attachment).tap do |a|
      allow(a)
        .to receive(:marked_for_destruction?)
        .and_return(attachment_marked_for_destruction)

      allow(a)
        .to receive(:destroy)
    end
  end
  let(:attachment_marked_for_destruction) { false }
  let(:attachments) { [ifc_attachment, other_attachment] }

  describe 'call' do
    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject.success?).to be_truthy
    end

    it 'returns the result of the SetAttributesService' do
      expect(subject)
        .to eql set_attributes_result
    end

    it 'persists the model' do
      expect(model)
        .to receive(:save)
        .and_return(model_valid)

      subject
    end

    it 'returns the model' do
      expect(subject.result)
        .to eql model
    end

    it 'schedules no conversion job' do
      expect(conversion_job)
        .not_to receive(:perform_later)

      subject
    end

    it 'leaves attachments not marked for destruction' do
      expect(other_attachment)
        .not_to receive(:destroy)

      subject
    end

    context 'if the attachment is altered' do
      let(:attachment_marked_for_destruction) { true }
      before do
        allow(ifc_attachment)
          .to receive(:new_record?)
          .and_return(true)
      end

      it 'schedules conversion job' do
        expect(conversion_job)
          .to receive(:perform_later)
          .with(model)

        subject
      end

      it 'destroys all attachments marked for destruction' do
        expect(other_attachment)
          .to receive(:destroy)

        subject
      end
    end

    context 'if the SetAttributeService is unsuccessful' do
      let(:set_attributes_success) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it 'returns the result of the SetAttributesService' do
        expect(subject)
          .to eql set_attributes_result
      end

      it 'does not persist the changes' do
        expect(model)
          .to_not receive(:save)

        subject
      end

      it "exposes the contract's errors" do
        subject

        expect(subject.errors).to eql set_attributes_errors
      end

      context 'if the attachment is altered' do
        let(:attachment_marked_for_destruction) { true }
        before do
          allow(ifc_attachment)
            .to receive(:new_record?)
            .and_return(true)
        end

        it 'schedules no conversion job' do
          expect(conversion_job)
            .not_to receive(:perform_later)

          subject
        end

        it 'does not destroy attachments marked for destruction' do
          expect(other_attachment)
            .not_to receive(:destroy)

          subject
        end
      end
    end

    context 'if the model is invalid' do
      let(:model_valid) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it "exposes the model's errors" do
        subject

        expect(subject.errors).to eql model.errors
      end
    end
  end
end
