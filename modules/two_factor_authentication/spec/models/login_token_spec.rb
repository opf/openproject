require_relative '../spec_helper'

describe TwoFactorAuthentication::LoginToken, with_2fa_ee: true do
  before do
    @user = build_stubbed(:user, login: "john", password: "doe")
    allow(@user).to receive(:new_record?).and_return(false)
    allow(@user).to receive(:force_password_reset).and_return(false)
    allow(@user).to receive(:password_expired?).and_return(false)
    allow(@user).to receive(:phone_verified?).and_return(true)
    @token = described_class.new(user: @user)
    @token.save
  end

  it "expires after 15 minutes" do
    time = Time.now + 16.minutes
    allow(Time).to receive(:now).and_return(time)
    expect(@token.expired?).to be(true)
  end

  it "does not expire before 15 minutes" do
    time = Time.now + 14.minutes
    allow(Time).to receive(:now).and_return(time)
    expect(@token.expired?).to be(false)
  end

  it "deletes previous tokens for the user on creation" do
    @new_token = described_class.new(user: @user)
    @new_token.save
    expect(described_class.find_by_id(@token.id)).to be_nil
    expect(described_class.find(@new_token.id)).not_to be_nil
  end
end
