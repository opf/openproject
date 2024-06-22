require "spec_helper"

RSpec.describe Ldap::ImportUsersFromListService do
  include_context "with temporary LDAP"

  subject do
    described_class.new(ldap_auth_source, user_list).call
  end

  let(:user_list) do
    %w[aa729 bb459 cc414]
  end

  it "adds all three users" do
    subject

    user_aa729 = User.find_by(login: "aa729")
    expect(user_aa729).to be_present
    expect(user_aa729.firstname).to eq "Alexandra"
    expect(user_aa729.lastname).to eq "Adams"

    user_bb459 = User.find_by(login: "bb459")
    expect(user_bb459).to be_present
    expect(user_bb459.firstname).to eq "Belle"
    expect(user_bb459.lastname).to eq "Baldwin"

    user_cc414 = User.find_by(login: "cc414")
    expect(user_cc414).to be_present
    expect(user_cc414.firstname).to eq "Claire"
    expect(user_cc414.lastname).to eq "Carpenter"
  end

  context "when two users already exist" do
    let!(:user_aa729) { create(:user, login: "aa729", firstname: "Foobar", ldap_auth_source:) }
    let!(:user_bb459) { create(:user, login: "bb459", firstname: "Bla", ldap_auth_source:) }

    it "adds the third one, but does not update the other two" do
      subject

      user_aa729.reload
      user_bb459.reload

      expect(user_aa729.firstname).to eq "Foobar"
      expect(user_aa729.lastname).to eq "Bobbit"
      expect(user_bb459.firstname).to eq "Bla"
      expect(user_bb459.lastname).to eq "Bobbit"

      user_cc414 = User.find_by(login: "cc414")
      expect(user_cc414).to be_present
      expect(user_cc414.firstname).to eq "Claire"
      expect(user_cc414.lastname).to eq "Carpenter"
    end
  end
end
