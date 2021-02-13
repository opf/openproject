#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::Filter::ProjectFilter, type: :model do
  let(:query) { FactoryBot.build :query }
  let(:instance) do
    described_class.create!(name: 'project', context: query, operator: '=', values: [])
  end

  describe '#allowed_values' do
    let!(:project) { FactoryBot.create :project }
    let!(:archived_project) { FactoryBot.create :project, active: false }

    let(:user) { FactoryBot.create(:user, member_in_projects: [project, archived_project], member_through_role: role) }
    let(:role) { FactoryBot.create :role, permissions: %i(view_work_packages) }

    before do
      login_as user
    end

    it 'does not include the archived project (Regression #36026)' do
      expect(instance.allowed_values)
        .to match_array [[project.name, project.id.to_s]]
    end
  end
end
