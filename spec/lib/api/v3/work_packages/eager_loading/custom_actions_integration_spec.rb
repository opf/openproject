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
#++require 'rspec'

require "spec_helper"
require_relative "eager_loading_mock_wrapper"

RSpec.describe API::V3::WorkPackages::EagerLoading::CustomAction do
  let!(:work_package1) { create(:work_package) }
  let!(:work_package2) { create(:work_package) }
  let!(:user) do
    create(:user,
           member_with_roles: { work_package2.project => role })
  end
  let!(:role) { create(:project_role) }
  let!(:status_custom_action) do
    create(:custom_action,
           conditions: [CustomActions::Conditions::Status.new(work_package1.status_id.to_s)])
  end
  let!(:role_custom_action) do
    create(:custom_action,
           conditions: [CustomActions::Conditions::Role.new(role.id)])
  end

  before do
    login_as(user)
  end

  describe ".apply" do
    it "preloads the correct custom_actions" do
      wrapped = EagerLoadingMockWrapper.wrap(described_class, [work_package1, work_package2])

      expect(work_package1)
        .not_to receive(:custom_actions)
      expect(work_package2)
        .not_to receive(:custom_actions)

      expect(wrapped.detect { |w| w.id == work_package1.id }.custom_actions(user))
        .to contain_exactly(status_custom_action)

      expect(wrapped.detect { |w| w.id == work_package2.id }.custom_actions(user))
        .to contain_exactly(role_custom_action)
    end
  end
end
