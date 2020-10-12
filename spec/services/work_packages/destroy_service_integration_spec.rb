#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackages::DeleteService, 'integration', type: :model do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: permissions)
  end

  let(:permissions) do
    %i(delete_work_packages view_work_packages add_work_packages manage_subtasks)
  end

  let(:project) { FactoryBot.create(:project) }

  describe 'deleting a child with estimated_hours set' do
    let(:parent) { FactoryBot.create(:work_package, project: project) }
    let(:child) do
      FactoryBot.create(:work_package,
                        project: project,
                        parent: parent,
                        estimated_hours: 123)
    end

    let(:instance) do
      described_class.new(user: user,
                          model: child)
    end
    subject { instance.call }

    before do
      # Ensure estimated_hours is inherited
      ::WorkPackages::UpdateAncestorsService.new(user: user, work_package: child).call(%i[estimated_hours])
      parent.reload
    end

    it 'updates the parent estimated_hours' do
      expect(child.estimated_hours).to eq 123
      expect(parent.derived_estimated_hours).to eq 123
      expect(parent.estimated_hours).to eq nil

      expect(subject).to be_success

      parent.reload

      expect(parent.estimated_hours).to eq(nil)
    end
  end
end
