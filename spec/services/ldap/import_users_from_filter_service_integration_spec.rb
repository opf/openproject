require "spec_helper"

RSpec.describe Ldap::ImportUsersFromFilterService do
  include_context "with temporary LDAP"

  subject do
    described_class.new(ldap_auth_source, filter).call
  end

  let(:filter) { Net::LDAP::Filter.from_rfc2254 "(uid=aa729)" }

  it "adds only the matching user" do
    subject

    user_aa729 = User.find_by(login: "aa729")
    expect(user_aa729).to be_present
    expect(user_aa729.firstname).to eq "Alexandra"
    expect(user_aa729.lastname).to eq "Adams"

    user_bb459 = User.find_by(login: "bb459")
    expect(user_bb459).not_to be_present

    user_cc414 = User.find_by(login: "cc414")
    expect(user_cc414).not_to be_present
  end
end
