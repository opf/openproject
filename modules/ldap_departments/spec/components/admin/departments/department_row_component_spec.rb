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

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::DepartmentRowComponent, type: :component do
  let(:department) { create(:department, lastname: "IT") }

  context "when the department is not managed by LDAP" do
    it "renders the action menu" do
      render_inline(described_class.new(department:))

      expect(page).to have_css("action-menu")
      expect(page).to have_no_text(I18n.t(:label_managed_by_ldap))
    end
  end

  context "when the department is managed by LDAP" do
    before { create(:ldap_synchronized_department, group: department) }

    it "renders a managed label instead of the action menu" do
      render_inline(described_class.new(department: department.reload))

      expect(page).to have_text(I18n.t(:label_managed_by_ldap))
      expect(page).to have_no_css("action-menu")
    end
  end
end
