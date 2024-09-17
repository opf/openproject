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

RSpec.describe Calendar::ResolveWorkPackagesService, type: :model do
  let(:user1) do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_work_packages] }
  let(:project) { create(:project) }
  let(:work_package_without_dates) do
    create(:work_package, project:)
  end
  let(:work_package_with_due_date) do
    create(:work_package, project:,
                          due_date: Time.zone.today + 7.days)
  end
  let(:work_package_with_start_date) do
    create(:work_package, project:,
                          start_date: Time.zone.today + 14.days)
  end
  let(:work_package_with_start_and_due_date) do
    create(:work_package, project:,
                          start_date: Date.tomorrow,
                          due_date: Time.zone.today + 7.days)
  end
  let(:work_package_with_due_date_far_in_the_past) do
    create(:work_package, project:,
                          due_date: Time.zone.today - 180.days)
  end
  let(:work_package_with_due_date_far_in_the_future) do
    create(:work_package, project:,
                          due_date: Time.zone.today + 180.days)
  end
  let(:work_packages) do
    [
      work_package_without_dates,
      work_package_with_due_date,
      work_package_with_start_date,
      work_package_with_start_and_due_date,
      work_package_with_due_date_far_in_the_past,
      work_package_with_due_date_far_in_the_future
    ]
  end
  let(:query) do
    create(:query_with_view_work_packages_calendar,
           project:,
           user: user1,
           public: false) do |query|
      # add typical filter for calendar queries
      query.add_filter(:dates_interval, "<>d", [Time.zone.today, Time.zone.today + 30.days])
    end
  end

  let(:instance) do
    described_class.new
  end

  context "for a valid query" do
    before do
      # login for this isolated test:
      # in context of the whole iCalendar API flow, the user is not logged in but resolved from the token
      # `User.execute_as()`` is then used in the service calling the service which is tested here
      login_as(user1)
    end

    subject { instance.call(query:) }

    it "returns work_packages of query with start and due date as result" do
      result = subject.result

      expect(result)
        .to include(
          work_package_with_start_date,
          work_package_with_due_date,
          work_package_with_start_and_due_date,
          work_package_with_due_date_far_in_the_past,
          work_package_with_due_date_far_in_the_future
        )
      expect(result)
        .not_to include(work_package_without_dates)
    end

    it "is a success" do
      expect(subject)
        .to be_success
    end
  end

  context "if query is nil" do
    before do
      login_as(user1)
    end

    subject { instance.call(query: nil) }

    it "does not resolve work_packages and raises ActiveRecord::RecordNotFound" do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
