# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "LDAP synchronized departments", :aggregate_failures, :skip_csrf,
               type: :rails_request, with_ee: %i[ldap_groups] do
  shared_let(:admin) { create(:admin) }
  shared_let(:ldap_auth_source) { create(:ldap_auth_source, base_dn: "dc=example,dc=com") }

  let(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:) }
  let(:department) { create(:department, lastname: "Frontend") }
  let!(:synced) { create(:ldap_synchronized_department, synchronized_tree: tree, group: department) }

  before { login_as(admin) }

  describe "GET /ldap_departments/synchronized_departments/:id/deletion_dialog" do
    it "renders the danger dialog explaining the department is kept" do
      get deletion_dialog_ldap_departments_synchronized_department_path(department_id: synced.id), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("ldap_departments.synchronized_departments.destroy.info"))
    end
  end

  describe "DELETE /ldap_departments/synchronized_departments/:id" do
    it "unlinks the department but keeps it" do
      expect { delete ldap_departments_synchronized_department_path(department_id: synced.id) }
        .to change(LdapDepartments::SynchronizedDepartment, :count).by(-1)

      expect(Group.exists?(department.id)).to be(true)
    end
  end
end
