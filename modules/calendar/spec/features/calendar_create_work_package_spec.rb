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
require_relative "shared_context"

RSpec.describe "Calendar create new work package", :js do
  include_context "with calendar full access"

  let(:type_task) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }

  before do
    login_as current_user
    project.types << type_task
  end

  it "can create a new work package" do
    calendar.visit!

    start_of_week = Time.zone.today.beginning_of_week(:sunday)
    split_create = calendar.add_item start_of_week.iso8601,
                                     (start_of_week + 1.day).iso8601

    subject = split_create.edit_field(:subject)
    subject.set_value "Newly planned task"

    split_create.save!

    split_create.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_create"))

    split_create.expect_attributes(
      combinedDate: "#{start_of_week.strftime('%m/%d/%Y')} - #{(start_of_week + 1.day).strftime('%m/%d/%Y')}"
    )

    wp = WorkPackage.last
    expect(wp.subject).to eq "Newly planned task"
    expect(wp.start_date).to eq start_of_week
    expect(wp.due_date).to eq (start_of_week + 1.day)

    calendar.expect_event wp
  end
end
