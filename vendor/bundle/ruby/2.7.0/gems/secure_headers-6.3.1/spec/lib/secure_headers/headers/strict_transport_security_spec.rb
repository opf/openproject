# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe StrictTransportSecurity do
    describe "#value" do
      specify { expect(StrictTransportSecurity.make_header).to eq([StrictTransportSecurity::HEADER_NAME, StrictTransportSecurity::DEFAULT_VALUE]) }
      specify { expect(StrictTransportSecurity.make_header("max-age=1234; includeSubdomains; preload")).to eq([StrictTransportSecurity::HEADER_NAME, "max-age=1234; includeSubdomains; preload"]) }

      context "with an invalid configuration" do
        context "with a string argument" do
          it "raises an exception with an invalid max-age" do
            expect do
              StrictTransportSecurity.validate_config!("max-age=abc123")
            end.to raise_error(STSConfigError)
          end

          it "raises an exception if max-age is not supplied" do
            expect do
              StrictTransportSecurity.validate_config!("includeSubdomains")
            end.to raise_error(STSConfigError)
          end

          it "raises an exception with an invalid format" do
            expect do
              StrictTransportSecurity.validate_config!("max-age=123includeSubdomains")
            end.to raise_error(STSConfigError)
          end
        end
      end
    end
  end
end
