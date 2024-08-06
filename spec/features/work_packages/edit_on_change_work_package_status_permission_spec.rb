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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "edit work package", :js do
  let(:current_user) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => role })
  end
  let(:permissions) { %i[view_work_packages change_work_package_status] }
  let(:role) { create(:project_role, permissions:) }

  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }
  let(:status_new) { create(:status, name: "New") }
  let(:status_done) { create(:status, name: "Done") }
  let(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: status_new,
           new_status: status_done,
           role:)
  end
  let(:work_package) do
    create(:work_package,
           author: current_user,
           status: status_new,
           project:,
           type:,
           created_at: 5.days.ago.to_date.to_fs(:db))
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  before do
    workflow

    login_as(current_user)
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  context "as a user having only the change_work_package_status permission" do
    it "can only change the status" do
      status_field = wp_page.edit_field :status
      status_field.expect_state_text status_new.name
      status_field.update status_done.name

      wp_page.expect_toast(message: "Successful update")
      status_field.expect_state_text status_done.name

      subject_field = wp_page.work_package_field("subject")
      subject_field.expect_read_only
    end
  end

  context "as a user having only the edit_work_packages permission" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    it "can change the status" do
      status_field = wp_page.edit_field :status
      status_field.expect_state_text status_new.name
      status_field.update status_done.name

      wp_page.expect_toast(message: "Successful update")
      status_field.expect_state_text status_done.name
    end
  end
end
