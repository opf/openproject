# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Principals::DeleteJob, "LDAP departments", type: :model do
  subject(:job) { described_class.perform_now(user) }

  shared_let(:deleted_user) { create(:deleted_user) }

  let(:department) { create(:department, lastname: "Frontend") }
  let(:synchronized_department) { create(:ldap_synchronized_department, group: department) }
  let(:user) { create(:user) }

  before do
    synchronized_department.add_members!([user])
  end

  it "can delete a user that is a synchronized department member" do
    expect(LdapDepartments::Membership.where(user:)).to exist

    expect { job }.to change(LdapDepartments::Membership, :count).by(-1)

    expect(User.exists?(user.id)).to be(false)
    expect(LdapDepartments::Membership.where(user_id: user.id)).not_to exist
  end

  it "keeps the synchronized department itself" do
    job

    expect(Group.exists?(department.id)).to be(true)
    expect(LdapDepartments::SynchronizedDepartment.exists?(synchronized_department.id)).to be(true)
  end
end
