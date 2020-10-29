# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe XPermittedCrossDomainPolicies do
    specify { expect(XPermittedCrossDomainPolicies.make_header).to eq([XPermittedCrossDomainPolicies::HEADER_NAME, "none"]) }
    specify { expect(XPermittedCrossDomainPolicies.make_header("master-only")).to eq([XPermittedCrossDomainPolicies::HEADER_NAME, "master-only"]) }

    context "valid configuration values" do
      it "accepts 'all'" do
        expect do
          XPermittedCrossDomainPolicies.validate_config!("all")
        end.not_to raise_error
      end

      it "accepts 'by-ftp-filename'" do
        expect do
          XPermittedCrossDomainPolicies.validate_config!("by-ftp-filename")
        end.not_to raise_error
      end

      it "accepts 'by-content-type'" do
        expect do
          XPermittedCrossDomainPolicies.validate_config!("by-content-type")
        end.not_to raise_error
      end
      it "accepts 'master-only'" do
        expect do
          XPermittedCrossDomainPolicies.validate_config!("master-only")
        end.not_to raise_error
      end

      it "accepts nil" do
        expect do
          XPermittedCrossDomainPolicies.validate_config!(nil)
        end.not_to raise_error
      end
    end

    context "invlaid configuration values" do
      it "doesn't accept invalid values" do
        expect do
          XPermittedCrossDomainPolicies.validate_config!("open")
        end.to raise_error(XPCDPConfigError)
      end
    end
  end
end
