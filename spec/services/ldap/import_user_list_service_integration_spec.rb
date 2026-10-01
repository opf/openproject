# frozen_string_literal: true

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

  context "with a required user custom field" do
    let!(:custom_field) { create(:user_custom_field, :string, name: "Employee ID", is_required: true) }

    it "still adds all three users, as LDAP cannot provide a value for the custom field" do
      subject

      expect(User.where(login: user_list).count).to eq 3
    end

    it "leaves the custom field empty" do
      subject

      expect(User.find_by(login: "aa729").custom_value_for(custom_field).value).to be_nil
    end
  end

  context "when two users already exist" do
    let!(:user_aa729) { create(:user, login: "aa729", firstname: "Foobar", lastname: "Bobbit", ldap_auth_source:) }
    let!(:user_bb459) { create(:user, login: "bb459", firstname: "Bla", lastname: "Bobbit", ldap_auth_source:) }

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
