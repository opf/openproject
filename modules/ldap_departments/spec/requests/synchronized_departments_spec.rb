# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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
