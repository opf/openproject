require_relative "../spec_helper"

RSpec.describe TwoFactorAuthentication::LoginToken, :with_2fa_ee do
  shared_let(:user) { create(:user) }
  let!(:token) { described_class.new user: }

  it "expires after 15 minutes" do
    Timecop.travel(16.minutes.from_now) do
      expect(token).to be_expired
    end
  end

  it "does not expire before 15 minutes" do
    Timecop.travel(14.minutes.from_now) do
      expect(token).not_to be_expired
    end
  end

  it "deletes previous tokens for the user on creation" do
    token.save!

    new_token = described_class.new(user:)
    new_token.save!

    expect(described_class.find_by(id: token.id)).to be_nil
    expect(described_class.find(new_token.id)).not_to be_nil
  end
end
