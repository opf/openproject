#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++require 'rspec'

require 'spec_helper'

describe ::API::V3::WorkPackages::CustomActions::CustomActionsWrapper do
  let!(:work_package1) { FactoryGirl.create(:work_package) }
  let!(:work_package2) { FactoryGirl.create(:work_package) }
  let!(:user) do
    FactoryGirl.create(:user,
                       member_in_project: work_package2.project,
                       member_through_role: role)
  end
  let!(:role) { FactoryGirl.create(:role) }
  let!(:status_custom_action) do
    FactoryGirl.create(:custom_action,
                       conditions: [CustomActions::Conditions::Status.new(work_package1.status_id.to_s)])
  end
  let!(:role_custom_action) do
    FactoryGirl.create(:custom_action,
                       conditions: [CustomActions::Conditions::Role.new(role.id)])
  end

  describe '.wrap' do
    it 'preloads the correct custom_actions' do
      wrapped = described_class
                .wrap([work_package1, work_package2], user)

      expect(work_package1)
        .not_to receive(:custom_actions)
      expect(work_package2)
        .not_to receive(:custom_actions)

      expect(wrapped.detect { |w| w.work_package == work_package1 }.custom_actions(user))
        .to match_array [status_custom_action]

      expect(wrapped.detect { |w| w.work_package == work_package2 }.custom_actions(user))
        .to match_array [role_custom_action]
    end
  end
end
