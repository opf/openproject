require "spec_helper"

RSpec.describe Bim::IfcModels::ViewConverterService do
  let(:model) { build(:ifc_model) }

  subject { described_class.new(model) }

  before do
    described_class.instance_variable_set(:@available_commands, nil)
  end

  shared_context "with available pipeline commands" do |available|
    before do
      # Mock the call to Open3 to test available commands
      allow(Open3)
        .to(receive(:capture2e))
        .with("which", any_args)
        .and_wrap_original do |_, *args|
        matches = if available.is_a?(Array)
                    available.include?(args[1])
                  else
                    available
                  end

        result = OpenStruct.new(exitstatus: matches ? 0 : 1)
        ["irrelevant output", result]
      end
    end
  end

  describe "#available_commands" do
    subject { described_class }

    context "with only one available command" do
      include_context "with available pipeline commands", %w[IfcConvert]

      it "is not available" do
        expect(subject).not_to be_available
      end
    end

    context "with all available commands" do
      include_context "with available pipeline commands", described_class::PIPELINE_COMMANDS

      it "is available" do
        expect(subject).to be_available
      end
    end
  end

  describe "#call" do
    before do
      allow(model).to receive(:processing!).and_call_original
    end

    context "if not available?" do
      include_context "with available pipeline commands", false

      it "returns an error" do
        expect(model).to receive(:processing!).and_call_original
        expect(described_class).not_to be_available
        result = subject.call
        expect(result.errors[:base].first).to include "The following IFC converter commands are missing"

        # Expect that the model's conversion status gets updated
        expect(model).to be_error
        expect(model.conversion_error_message).to include("The following IFC converter commands are missing")
      end
    end

    context "if available" do
      let(:working_directory) { Dir.mktmpdir }
      let(:ifc_model_file_name) { "büro.ifc" }
      let(:ifc_model_path) { File.join working_directory, ifc_model_file_name }
      let(:ext_regex) { /\.[^.]*\Z/ }

      before do
        allow(described_class).to receive(:available?).and_return true

        FileUtils.touch ifc_model_path

        allow(subject).to receive(:ifc_model_path).and_return(ifc_model_path)
        allow(subject).to receive(:working_directory).and_return(working_directory)

        model.conversion_status = Bim::IfcModels::IfcModel.conversion_statuses[:error]
        model.conversion_error_message = "Some message"
      end

      after do
        FileUtils.remove_entry working_directory
      end

      it "performs the conversion and returns the save result" do
        allow(model).to receive(:processing!).and_call_original

        # mocking all convert! calls so they do nothing but create an empty dummy result file
        allow(subject).to receive(:convert!) do |source_file, ext|
          expect(File.exist?(source_file)).to be_truthy, "Expected #{source_file} to exist."

          target_file_path = source_file.sub ext_regex, "." + ext

          FileUtils.touch target_file_path

          target_file_path
        end

        # expect conversion pipeline to start with generic model.ifc and end with
        # büro.xkt based on the original file name

        expect(subject)
          .to receive(:convert_to_collada)
          .with(File.join(working_directory, "model.ifc"))
          .and_call_original

        expect(subject)
          .to receive(:convert_to_gltf)
          .with(File.join(working_directory, "model.dae"))
          .and_call_original

        expect(subject)
          .to receive(:convert_to_xkt)
          .with(File.join(working_directory, "model.gltf"))
          .and_call_original

        expect(model)
          .to receive(:xkt_attachment=) { |file|
            expect(file.path).to end_with(ifc_model_file_name.sub(ext_regex, ".xkt"))
          }

        # expect metadata conversion starting with generic model.ifc and ending
        # with büro.json based on the original file name

        expect(subject)
          .to receive(:convert_metadata)
          .with(File.join(working_directory, "model.ifc"))
          .and_call_original

        expect(model).to receive(:save).and_return(true)

        expect(subject.call).to be_success

        # Expect that the model's conversion status gets updated
        expect(model).to be_completed
        expect(model.conversion_error_message).to be_nil
      end

      it "calls the conversion and returns error" do
        expect(subject)
          .to(receive(:perform_conversion!))

        expect(model)
          .to(receive(:save))
          .and_return(false)

        expect(subject.call).not_to be_success
      end
    end
  end

  describe "#change_basename" do
    it "returns the new basename" do
      path = "/tmp/file.xml"
      new_path = subject.send(:change_basename, path, "/home/model.xml", ".json")

      expect(new_path.to_s).to eq "/tmp/model.json"
    end
  end
end
