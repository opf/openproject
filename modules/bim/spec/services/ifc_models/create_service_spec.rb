require 'spec_helper'

describe Bim::IfcModels::CreateService do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    double('contract_class', '<=': true)
  end
  let(:model_valid) { true }
  let(:instance) do
    described_class.new(user: user,
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
    ServiceResult.new result: created_model,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:created_model) do
    model = FactoryBot.build_stubbed(:ifc_model)

    allow(Bim::IfcModels::IfcModel)
      .to receive(:new)
      .and_return(model)

    allow(model)
      .to receive(:save)
      .and_return(model_valid)

    model
  end
  let!(:set_attributes_service) do
    service = double('set_attributes_service_instance')

    allow(Bim::IfcModels::SetAttributesService)
      .to receive(:new)
      .with(user: user,
            model: created_model,
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
      expect(created_model)
        .to receive(:save)
        .and_return(model_valid)

      subject
    end

    it 'returns the model' do
      expect(subject.result)
        .to eql created_model
    end

    it 'queues a conversion job' do
      expect(conversion_job)
        .to receive(:perform_later)
        .with(created_model)

      subject
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
        expect(created_model)
          .to_not receive(:save)

        subject
      end

      it "exposes the contract's errors" do
        subject

        expect(subject.errors).to eql set_attributes_errors
      end

      it 'queues no conversion job' do
        expect(conversion_job)
          .not_to receive(:perform_later)

        subject
      end
    end

    context 'when the model is invalid' do
      let(:model_valid) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it "exposes the model's errors" do
        subject

        expect(subject.errors).to eql created_model.errors
      end

      it 'queues no conversion job' do
        expect(conversion_job)
          .not_to receive(:perform_later)

        subject
      end
    end
  end
end
