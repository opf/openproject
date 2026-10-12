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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec.shared_context "with a health check context" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end

  let(:work_package_status) { open_status }
  let(:work_package) { create(:work_package, project:, status: work_package_status) }
  let(:context) do
    AI::AssistantSkills::HealthCheck::Context.new(work_package: work_package.reload, user:)
  end

  def child_of(parent, status:, project: parent.project, updated_at: nil)
    create(:work_package, project:, parent:, status:).tap do |wp|
      wp.update_column(:updated_at, updated_at) if updated_at
    end
  end
end
