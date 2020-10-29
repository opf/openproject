# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe XFrameOptions do
    describe "#value" do
      specify { expect(XFrameOptions.make_header).to eq([XFrameOptions::HEADER_NAME, XFrameOptions::DEFAULT_VALUE]) }
      specify { expect(XFrameOptions.make_header("DENY")).to eq([XFrameOptions::HEADER_NAME, "DENY"]) }

      context "with invalid configuration" do
        it "allows SAMEORIGIN" do
          expect do
            XFrameOptions.validate_config!("SAMEORIGIN")
          end.not_to raise_error
        end

        it "allows DENY" do
          expect do
            XFrameOptions.validate_config!("DENY")
          end.not_to raise_error
        end

        it "allows ALLOW-FROM*" do
          expect do
            XFrameOptions.validate_config!("ALLOW-FROM: example.com")
          end.not_to raise_error
        end
        it "does not allow garbage" do
          expect do
            XFrameOptions.validate_config!("I like turtles")
          end.to raise_error(XFOConfigError)
        end
      end
    end
  end
end
