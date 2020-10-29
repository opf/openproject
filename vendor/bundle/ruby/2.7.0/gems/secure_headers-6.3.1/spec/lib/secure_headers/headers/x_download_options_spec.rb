# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe XDownloadOptions do
    specify { expect(XDownloadOptions.make_header).to eq([XDownloadOptions::HEADER_NAME, XDownloadOptions::DEFAULT_VALUE]) }
    specify { expect(XDownloadOptions.make_header("noopen")).to eq([XDownloadOptions::HEADER_NAME, "noopen"]) }

    context "invalid configuration values" do
      it "accepts noopen" do
        expect do
          XDownloadOptions.validate_config!("noopen")
        end.not_to raise_error
      end

      it "accepts nil" do
        expect do
          XDownloadOptions.validate_config!(nil)
        end.not_to raise_error
      end

      it "doesn't accept anything besides noopen" do
        expect do
          XDownloadOptions.validate_config!("open")
        end.to raise_error(XDOConfigError)
      end
    end
  end
end
