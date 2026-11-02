# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::UserPreference do
  let(:user) { create(:user) }

  it "defaults to tips and badges on, without a row" do
    preference = described_class.for(user)
    expect(preference).to be_new_record
    expect(preference).to be_hotkey_tips_enabled
    expect(preference).to be_hotkey_hints_enabled
  end

  it "stores the switches per user" do
    described_class.for(user).assign_options("hotkey_tips" => "0", "hotkey_hints" => "1").save!

    stored = described_class.for(user)
    expect(stored).to be_persisted
    expect(stored).not_to be_hotkey_tips_enabled
    expect(stored).to be_hotkey_hints_enabled
    expect(described_class.for(create(:user))).to be_hotkey_tips_enabled
  end

  it "ignores unknown options" do
    preference = described_class.for(user).assign_options("admin" => true, "hotkey_tips" => false)
    expect(preference.options.keys).to eq(%w[hotkey_tips])
  end

  it "returns unsaved defaults for anonymous users" do
    preference = described_class.for(User.anonymous)
    expect(preference).to be_new_record
    expect(preference.user_id).to be_nil
    expect(preference).to be_hotkey_tips_enabled
  end

  it "does not touch core user preferences" do
    described_class.for(user).assign_options(hotkey_tips: false).save!
    expect(user.reload.pref.settings.keys.map(&:to_s)).not_to include("hotkey_tips")
  end
end
