RSpec.describe Airbrake::Config::Validator do
  let(:valid_id) { 123 }
  let(:valid_key) { '123' }
  let(:config) { Airbrake::Config.new(config_params) }

  describe ".validate" do
    context "when project_id is numerical" do
      let(:config_params) { { project_id: valid_id, project_key: valid_key } }

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end

    context "when project_id is a numerical String" do
      let(:config_params) { { project_id: '123', project_key: valid_key } }

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end

    context "when project_id is zero" do
      let(:config_params) { { project_id: 0, project_key: valid_key } }

      it "returns a rejected promise" do
        promise = described_class.validate(config)
        expect(promise.value).to eq('error' => ':project_id is required')
      end
    end

    context "when project_id consists of letters" do
      let(:config_params) { { project_id: 'foo', project_key: valid_key } }

      it "returns a rejected promise" do
        promise = described_class.validate(config)
        expect(promise.value).to eq('error' => ':project_id is required')
      end
    end

    context "when project_id is less than zero" do
      let(:config_params) { { project_id: -123, project_key: valid_key } }

      it "returns a rejected promise" do
        promise = described_class.validate(config)
        expect(promise.value).to eq('error' => ':project_id is required')
      end
    end

    context "when project_key is a non-empty String" do
      let(:config_params) { { project_id: valid_id, project_key: '123' } }

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end

    context "when project_key is an empty String" do
      let(:config_params) { { project_id: valid_id, project_key: '' } }

      it "returns a rejected promise" do
        promise = described_class.validate(config)
        expect(promise.value).to eq('error' => ':project_key is required')
      end
    end

    context "when project_key is a non-String" do
      let(:config_params) { { project_id: valid_id, project_key: 123 } }

      it "returns a rejected promise" do
        promise = described_class.validate(config)
        expect(promise.value).to eq('error' => ':project_key is required')
      end
    end

    context "when environment is nil" do
      let(:config_params) do
        { project_id: valid_id, project_key: valid_key, environment: nil }
      end

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end

    context "when environment is a String" do
      let(:config_params) do
        { project_id: valid_id, project_key: valid_key, environment: 'test' }
      end

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end

    context "when environment is a Symbol" do
      let(:config_params) do
        { project_id: valid_id, project_key: valid_key, environment: :test }
      end

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end

    context "when environment is non-String and non-Symbol" do
      let(:config_params) do
        { project_id: valid_id, project_key: valid_key, environment: 1.0 }
      end

      it "returns a rejected promise" do
        promise = described_class.validate(config)
        expect(promise.value).to eq(
          'error' => "the 'environment' option must be configured with a " \
                     "Symbol (or String), but 'Float' was provided: 1.0",
        )
      end
    end

    context "when environment is String-like" do
      let(:string_inquirer) { Class.new(String) }

      let(:config_params) do
        {
          project_id: valid_id,
          project_key: valid_key,
          environment: string_inquirer.new('test'),
        }
      end

      it "returns a resolved promise" do
        promise = described_class.validate(config)
        expect(promise).to be_resolved
      end
    end
  end

  describe "#check_notify_ability" do
    context "when current environment is ignored" do
      let(:config_params) do
        {
          project_id: valid_id,
          project_key: valid_key,
          environment: 'test',
          ignore_environments: ['test'],
        }
      end

      it "returns a rejected promise" do
        promise = described_class.check_notify_ability(config)
        expect(promise.value).to eq(
          'error' => "current environment 'test' is ignored",
        )
      end
    end

    context "when no environment is specified but ignore_environments is" do
      let(:config_params) do
        {
          project_id: valid_id,
          project_key: valid_key,
          ignore_environments: ['test'],
        }
      end

      it "returns a resolved promise" do
        promise = described_class.check_notify_ability(config)
        expect(promise).to be_resolved
      end

      it "warns about 'no effect'" do
        expect(config.logger).to receive(:warn)
          .with(/'ignore_environments' has no effect/)
        described_class.check_notify_ability(config)
      end
    end

    context "when the error_notifications option is false" do
      let(:config_params) do
        {
          project_id: valid_id,
          project_key: valid_key,
          error_notifications: false,
        }
      end

      it "returns a rejected promise" do
        promise = described_class.check_notify_ability(config)
        expect(promise.value).to eq(
          'error' => "error notifications are disabled",
        )
      end
    end
  end
end
