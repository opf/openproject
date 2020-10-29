# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe XContentTypeOptions do
    describe "#value" do
      specify { expect(XContentTypeOptions.make_header).to eq([XContentTypeOptions::HEADER_NAME, XContentTypeOptions::DEFAULT_VALUE]) }
      specify { expect(XContentTypeOptions.make_header("nosniff")).to eq([XContentTypeOptions::HEADER_NAME, "nosniff"]) }

      context "invalid configuration values" do
        it "accepts nosniff" do
          expect do
            XContentTypeOptions.validate_config!("nosniff")
          end.not_to raise_error
        end

        it "accepts nil" do
          expect do
            XContentTypeOptions.validate_config!(nil)
          end.not_to raise_error
        end

        it "doesn't accept anything besides no-sniff" do
          expect do
            XContentTypeOptions.validate_config!("donkey")
          end.to raise_error(XContentTypeOptionsConfigError)
        end
      end
    end
  end
end
