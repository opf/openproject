#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::PrincipalAllowanceEvaluator::Default, type: :model do
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:instance) { described_class.new(user) }

  describe '#project_granting_candidates' do
    let(:project) { FactoryGirl.build_stubbed(:project) }

    subject { instance.project_granting_candidates(project) }

    it 'returns empty if the project is not active' do
      project.status = Project::STATUS_ARCHIVED

      is_expected.to match_array []
    end

    it 'returns the roles in the project' do
      project_role = double('project_role')
      other_role = double('other_role')
      project_member = double('project_member', project_id: project.id,
                                                roles: [project_role])
      other_member = double('other_member', project_id: 0,
                                            roles: [other_role])

      allow(user).to receive(:members).and_return([project_member, other_member])

      is_expected.to match_array [project_role]
    end

    it 'returns the non member role if no membership exist for the project' do
      other_member = double('other_member', project_id: 0)

      allow(user).to receive(:members).and_return([other_member])

      is_expected.to match_array [Role.non_member]
    end

    it 'returns the anonymous role if the user is not logged in' do
      allow(user).to receive(:logged?).and_return(false)

      is_expected.to match_array [Role.anonymous]
    end
  end
end
