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

RSpec.describe WorkPackages::TrashService, with_ee: %i[work_package_trash] do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(
      :user,
      member_with_permissions: {
        project => %i[
          view_work_packages
          view_work_packages_in_trash
          manage_work_package_trash
          delete_work_packages
        ]
      }
    )
  end

  let!(:work_package) { create(:work_package, project:) }
  let!(:child) { create(:work_package, project:, parent: work_package) }

  before { User.current = user }

  it "moves a hierarchy to trash, restores it, and permanently deletes it", :aggregate_failures do
    trash_result = WorkPackages::TrashService.new(user:, model: work_package).call

    expect(trash_result).to be_success
    expect(WorkPackage.find_by(id: work_package.id)).to be_nil

    trashed_root = WorkPackage.with_trashed.find(work_package.id)
    trashed_child = WorkPackage.with_trashed.find(child.id)
    expect(trashed_root.deleted_by).to eq(user)
    expect(trashed_root.deletion_group).to eq(trashed_child.deletion_group)

    restore_result = WorkPackages::RestoreService.new(user:, model: trashed_root).call

    expect(restore_result).to be_success
    expect(WorkPackage.find(work_package.id)).to be_present
    expect(WorkPackage.find(child.id).parent_id).to eq(work_package.id)

    WorkPackages::TrashService.new(user:, model: WorkPackage.find(work_package.id)).call
    purge_result = WorkPackages::PurgeService.new(
      user:,
      model: WorkPackage.with_trashed.find(work_package.id)
    ).call

    expect(purge_result).to be_success
    expect(WorkPackage.with_trashed.where(id: [work_package.id, child.id])).to be_empty
  end
end
