# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

require 'spec_helper'
require_relative '../../support/pages/work_packages/full_work_package'
require_relative '../../support/components/common/modal'

RSpec.describe 'Work package sharing', :js do
  let(:sharer_role) do
    create(:role,
           permissions: %i(view_work_packages
                           share_work_packages))
  end
  let(:view_work_package_role) do
    create(:work_package_role,
           permissions: %i(view_work_packages
                           edit_work_packages
                           work_package_assigned
                           add_work_package_notes
                           edit_own_work_package_notes
                           manage_work_package_relations
                           copy_work_packages
                           export_work_packages))
  end
  let(:comment_work_package_role) do
    create(:work_package_role,
           permissions: %i(view_work_packages
                           work_package_assigned
                           add_work_package_notes
                           edit_own_work_package_notes
                           export_work_packages))
  end
  let(:edit_work_package_role) do
    create(:work_package_role,
           permissions: %i(view_work_packages
                           export_work_packages))
  end
  let(:project) do
    create(:project,
           members: { current_user => [sharer_role],
                      # The roles of those users don't really matter, reusing the roles
                      # to save some creation work.
                      non_shared_project_user => [sharer_role],
                      shared_project_user => [sharer_role] })
  end
  let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:member, entity: wp, user: view_user, roles: [view_work_package_role])
      create(:member, entity: wp, user: comment_user, roles: [comment_work_package_role])
      create(:member, entity: wp, user: edit_user, roles: [edit_work_package_role])
      create(:member, entity: wp, user: shared_project_user, roles: [edit_work_package_role])
    end
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::Common::Modal.new }

  let!(:view_user) { create(:user) }
  let!(:comment_user) { create(:user) }
  let!(:edit_user) { create(:user) }
  let!(:non_shared_project_user) { create(:user) }
  let!(:shared_project_user) { create(:user) }

  current_user { create(:user) }

  it 'allows seeing and administrating sharing' do
    work_package_page.visit!

    # Clicking on the share button opens a modal which lists all of the users a work package
    # is explicitly shared with.
    # Project members are not listed unless the work package is also shared with them explicitly.
    click_button 'Share'

    share_modal.expect_open
    share_modal.expect_title('Share work package')
    # TODO: Move into specific share modal support class
    share_modal.expect_text(view_user.name)
    share_modal.expect_text(comment_user.name)
    share_modal.expect_text(edit_user.name)
    within share_modal.modal_element do
      expect(page).not_to have_text(non_shared_project_user.name)
    end
    share_modal.expect_text(shared_project_user.name)
  end
end
