# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe XXssProtection do
    specify { expect(XXssProtection.make_header).to eq([XXssProtection::HEADER_NAME, XXssProtection::DEFAULT_VALUE]) }
    specify { expect(XXssProtection.make_header("1; mode=block; report=https://www.secure.com/reports")).to eq([XXssProtection::HEADER_NAME, "1; mode=block; report=https://www.secure.com/reports"]) }

    context "with invalid configuration" do
      it "should raise an error when providing a string that is not valid" do
        expect do
          XXssProtection.validate_config!("asdf")
        end.to raise_error(XXssProtectionConfigError)

        expect do
          XXssProtection.validate_config!("asdf; mode=donkey")
        end.to raise_error(XXssProtectionConfigError)
      end

      context "when using a hash value" do
        it "should allow string values ('1' or '0' are the only valid strings)" do
          expect do
            XXssProtection.validate_config!("1")
          end.not_to raise_error
        end

        it "should raise an error if no value key is supplied" do
          expect do
            XXssProtection.validate_config!("mode=block")
          end.to raise_error(XXssProtectionConfigError)
        end

        it "should raise an error if an invalid key is supplied" do
          expect do
            XXssProtection.validate_config!("123")
          end.to raise_error(XXssProtectionConfigError)
        end

        it "should raise an error if mode != block" do
          expect do
            XXssProtection.validate_config!("1; mode=donkey")
          end.to raise_error(XXssProtectionConfigError)
        end
      end
    end
  end
end
