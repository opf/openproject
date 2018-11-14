require_relative '../spec_helper'

describe TwoFactorAuthentication::LoginToken, with_2fa_ee: true do

  before(:each) do
    @user = mock_model(User, :login => "john", :password => "doe")
    allow(@user).to receive(:new_record?).and_return(false)
    allow(@user).to receive(:force_password_reset).and_return(false)
    allow(@user).to receive(:password_expired?).and_return(false)
    allow(@user).to receive(:phone_verified?).and_return(true)
    @token = described_class.new( :user => @user )
    @token.save
  end

  it "should expire after 15 minutes" do
    time = Time.now + 16.minutes
    allow(Time).to receive(:now).and_return(time)
    expect(@token.expired?).to eq(true)
  end

  it "should not expire before 15 minutes" do
    time = Time.now + 14.minutes
    allow(Time).to receive(:now).and_return(time)
    expect(@token.expired?).to eq(false)
  end

  it "should delete previous tokens for the user on creation" do
    @new_token = described_class.new( :user => @user )
    @new_token.save
    expect(described_class.find_by_id( @token.id )).to eq(nil)
    expect(described_class.find( @new_token.id )).not_to eq(nil)
  end

end
