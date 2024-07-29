require "spec_helper"

RSpec.describe Users::SetTimezoneService do
  let(:instance) { described_class.new(user) }

  before do
    allow(Time).to receive(:zone=).and_call_original
    instance.call!
  end

  context "when the user has a timezone set" do
    let(:user) do
      build_stubbed(:user, preferences: { time_zone: "Asia/Tokyo" })
    end

    it "sets that timezone" do
      expect(Time).to have_received(:zone=).with(ActiveSupport::TimeZone["Asia/Tokyo"])
    end
  end

  context "when the user has no timezone set" do
    let(:user) do
      build_stubbed(:user, preferences: { time_zone: "" })
    end

    context "and default time zone is set", with_settings: { user_default_timezone: "Europe/Berlin" } do
      it "sets the default" do
        expect(Time).to have_received(:zone=).with(ActiveSupport::TimeZone["Europe/Berlin"])
      end
    end

    context "and default time zone is not set", with_settings: { user_default_timezone: nil } do
      it "does nothing" do
        expect(Time).not_to have_received(:zone=)
      end
    end
  end

  context "when user is anonymous" do
    let(:user) do
      User.anonymous
    end

    it "sets that timezone" do
      expect(Time).not_to have_received(:zone=)
    end
  end
end
