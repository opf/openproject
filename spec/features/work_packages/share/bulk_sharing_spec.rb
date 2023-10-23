# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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

RSpec.describe 'Work Packages', 'Bulk Sharing',
               :js, :with_cuprite,
               with_flag: { work_package_sharing: true } do
  shared_let(:view_work_package_role)    { create(:view_work_package_role)    }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }
  shared_let(:edit_work_package_role)    { create(:edit_work_package_role)    }

  shared_let(:sharer_role) do
    create(:project_role, permissions: %i[view_work_packages
                                          view_shared_work_packages
                                          share_work_packages])
  end

  shared_let(:sharer)       { create(:user, firstname: 'Sharer', lastname: 'User')   }
  shared_let(:project)      { create(:project, members: { sharer => [sharer_role] }) }

  shared_let(:dinesh)   { create(:user, firstname: 'Dinesh', lastname: 'Chugtai')    }
  shared_let(:gilfoyle) { create(:user, firstname: 'Bertram', lastname: 'Gilfoyle')  }
  shared_let(:richard)  { create(:user, firstname: 'Richard', lastname: 'Hendricks') }

  shared_let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:work_package_member, principal: richard,  entity: wp, roles: [view_work_package_role])
      create(:work_package_member, principal: dinesh,   entity: wp, roles: [edit_work_package_role])
      create(:work_package_member, principal: gilfoyle, entity: wp, roles: [comment_work_package_role])
    end
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package)               }
  let(:share_modal)       { Components::WorkPackages::ShareModal.new(work_package) }

  current_user { sharer }

  context 'when having share permission' do
    it 'allows administrating shares in bulk' do
      work_package_page.visit!

      click_button 'Share'
      share_modal.expect_open
      share_modal.expect_shared_count_of(3)

      aggregate_failures "Selection behavior" do
        # Selecting one individually
        share_modal.select_shares(richard)
        share_modal.expect_selected(richard)
        share_modal.expect_selected_count_of(1)
        share_modal.expect_select_all_untoggled

        # Toggling all selects all
        share_modal.toggle_select_all
        share_modal.expect_selected(richard, dinesh, gilfoyle)
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled

        # Deselecting one individually
        share_modal.deselect_shares(richard)
        share_modal.expect_selected(dinesh, gilfoyle)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled

        # Re-selecting the missing share
        share_modal.select_shares(richard)
        share_modal.expect_selected(richard, dinesh, gilfoyle)
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled

        # De-selecting all
        share_modal.toggle_select_all
        share_modal.expect_deselected(richard, dinesh, gilfoyle)
        share_modal.expect_shared_count_of(3)
        share_modal.expect_select_all_untoggled

        # Re-selecting all
        share_modal.toggle_select_all
        share_modal.expect_selected(richard, dinesh, gilfoyle)
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled

        # De-selecting all individually
        share_modal.deselect_shares(richard, dinesh, gilfoyle)
        share_modal.expect_shared_count_of(3)
        share_modal.expect_select_all_untoggled
      end

      aggregate_failures "Preserving selected states when performing individual updates" do
        share_modal.select_shares(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled

        share_modal.remove_user(gilfoyle)
        share_modal.expect_not_shared_with(gilfoyle)

        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_toggled

        share_modal.invite_user(gilfoyle, 'Comment')
        share_modal.expect_shared_with(gilfoyle)
        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled
      end

      aggregate_failures "Bulk deletion" do
        # Richard and Dinesh already selected from above
        share_modal.bulk_remove

        share_modal.expect_not_shared_with(richard, dinesh)
        share_modal.expect_shared_with(gilfoyle)
        share_modal.expect_shared_count_of(1)

        share_modal.select_shares(gilfoyle)
        share_modal.expect_selected_count_of(1)
        share_modal.expect_select_all_toggled
        share_modal.bulk_remove

        share_modal.expect_blankslate
      end
    end
  end
end
