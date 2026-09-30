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

RSpec.describe Admin::Departments::MoveUserDialogComponent, type: :component do
  let(:user) { create(:user) }
  let(:managed) { create(:department, lastname: "Managed") }
  let(:manual) { create(:department, lastname: "Manual") }

  context "when the source department is managed by LDAP" do
    before { create(:ldap_synchronized_department, group: managed) }

    it "shows an info message and offers no move action" do
      render_inline(described_class.new(user:, from_department: managed.reload, to_department: manual))

      expect(page).to have_text(I18n.t("departments.move_user_dialog.managed_heading"))
      expect(page).to have_no_text(I18n.t("departments.move_user_dialog.confirm"))
    end
  end

  context "when the source department is not managed by LDAP" do
    it "offers to move the user" do
      render_inline(described_class.new(user:, from_department: manual, to_department: managed))

      expect(page).to have_text(I18n.t("departments.move_user_dialog.heading"))
      expect(page).to have_no_text(I18n.t("departments.move_user_dialog.managed_heading"))
    end
  end
end
