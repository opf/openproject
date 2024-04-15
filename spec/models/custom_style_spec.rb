require "spec_helper"

RSpec.describe CustomStyle do
  describe "#current" do
    subject { CustomStyle.current }

    context "there is one in DB" do
      it "returns an instance" do
        CustomStyle.create
        expect(subject).to be_a CustomStyle
      end

      it "returns the same instance for subsequent calls" do
        CustomStyle.create
        first_instance = CustomStyle.current
        expect(subject).to be first_instance
      end
    end

    context "there is none in DB" do
      before do
        RequestStore.delete(:current_custom_style)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    shared_examples "removing an image from a custom style" do
      let(:image) { raise "define me!" }
      let(:custom_style) { create "custom_style_with_#{image}" }

      let!(:file_path) { custom_style.send(image).file.path }

      before do
        custom_style.send :"remove_#{image}"
      end

      it "deletes the file" do
        expect(File.exist?(file_path)).to be false
      end

      it "clears the file mount column" do
        expect(custom_style.reload.send(image).file).to be_nil
      end
    end

    describe "#remove_favicon" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "favicon" }
      end
    end

    describe "#remove_touch_icon" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "touch_icon" }
      end
    end

    describe "#remove_logo" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "logo" }
      end
    end

    describe "#remove_export_logo" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "export_logo" }
      end
    end

    describe "#remove_export_cover" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "export_cover" }
      end
    end
  end
end
