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

RSpec.describe TimeEntry, "visible scope" do
  let(:project) { create(:project) }

  let(:work_package) do
    create(:work_package,
           project:,
           author: user2)
  end
  let(:user2) do
    create(:user)
  end
  let!(:own_project_time_entry) do
    create(:time_entry,
           project:,
           work_package:,
           hours: 2,
           user:)
  end
  let!(:project_time_entry) do
    create(:time_entry,
           project:,
           work_package:,
           hours: 2,
           user: user2)
  end
  let!(:own_other_project_time_entry) do
    create(:time_entry,
           project: create(:project),
           user:)
  end

  describe ".visible" do
    subject { TimeEntry.visible(user) }

    context "for a user having the view_time_entries permission" do
      let(:user) { create(:user, member_with_permissions: { project => [:view_time_entries] }) }

      it "retrieves all the time entries of projects the user has the permissions in" do
        expect(subject)
          .to contain_exactly(own_project_time_entry, project_time_entry)
      end
    end

    context "for a user having the view_own_time_entries permission on a work package" do
      let(:user) { create(:user, member_with_permissions: { work_package => [:view_own_time_entries] }) }

      it "retrieves all the time entries of the user in projects the user has the permissions in" do
        expect(subject)
          .to contain_exactly(own_project_time_entry)
      end
    end
  end
end
