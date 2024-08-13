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

RSpec.describe TimeEntries::SetAttributesService, "integration", type: :model do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages log_time]
           })
  end
  let(:work_package) { create(:work_package, project:) }
  let(:time_entry_instance) { TimeEntry.new(params) }
  let(:instance) do
    described_class.new(user:, model: time_entry_instance, contract_class: TimeEntries::CreateContract)
  end

  let(:params) do
    {
      work_package:,
      spent_on: Time.zone.today,
      hours: 1
    }
  end

  subject { instance.call(params) }

  context "default activity not active in project" do
    let!(:default_activity) { create(:time_entry_activity, is_default: true) }

    before do
      project.time_entry_activities_projects.create(activity_id: default_activity.id, active: false)
    end

    it "does not assign the default activity" do
      expect(subject).to be_success
      expect(subject.result.activity).to be_nil
    end
  end
end
