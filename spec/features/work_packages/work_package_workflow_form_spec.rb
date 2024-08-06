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

RSpec.describe "Work package transitive status workflows", :js do
  let(:dev_role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           edit_work_packages])
  end
  let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => dev_role })
  end

  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  let(:work_package) do
    work_package = create(:work_package,
                          project:,
                          type:,
                          created_at: 5.days.ago.to_date.to_fs(:db))

    note_journal = work_package.journals.reload.last
    note_journal.update(created_at: 5.days.ago.to_date.to_s,
                        updated_at: 5.days.ago.to_date.to_s)

    work_package
  end
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  let(:status_from) { work_package.status }
  let(:status_intermediate) { create(:status) }
  let(:status_to) { create(:status) }

  let(:workflows) do
    create(:workflow,
           type_id: type.id,
           old_status: status_from,
           new_status: status_intermediate,
           role: dev_role)

    create(:workflow,
           type_id: type.id,
           old_status: status_intermediate,
           new_status: status_to,
           role: dev_role)
  end

  before do
    login_as(dev)

    work_package
    workflows

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  ##
  # Regression test for #24129
  it "allows to move to the final status as defined in the workflow" do
    wp_page.update_attributes status: status_intermediate.name
    wp_page.expect_attributes status: status_intermediate.name

    wp_page.expect_activity_message "Status changed from #{status_from.name} " \
                                    "to #{status_intermediate.name}"

    wp_page.update_attributes status: status_to.name
    wp_page.expect_attributes status: status_to.name

    wp_page.expect_activity_message "Status changed from #{status_from.name} " \
                                    "to #{status_to.name}"

    work_package.reload
    expect(work_package.status).to eq(status_to)
  end
end
