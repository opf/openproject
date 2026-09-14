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

require "spec_helper"
require_module_spec_helper

RSpec.describe WorkPackageMeetingsTab::MeetingComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:meeting) { create(:meeting, project:, title: "Sprint review") }
  let(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Discuss scope") }

  subject(:rendered_component) do
    render_inline(
      described_class.new(work_package:, meeting:, meeting_agenda_items: [agenda_item])
    )
  end

  it_behaves_like "rendering Box", row_count: 1

  it "renders a condensed box keyed to the meeting" do
    expect(rendered_component).to have_css(".Box.Box--condensed#op-meeting-container-#{meeting.id}")
  end

  it "renders the meeting title as a heading linking to the meeting", :aggregate_failures do
    expect(rendered_component).to have_css(".Box-header") do |header|
      expect(header).to have_css(
        "h4 a[href='#{meeting_path(meeting)}'][target='_blank']",
        text: "#{project.name}: #{meeting.title}"
      )
      expect(header).to have_css(
        "h4 .color-fg-muted",
        text: ApplicationController.helpers.format_time(meeting.start_time)
      )
      expect(header).to have_css(
        "h4",
        exact_text: "#{project.name}: #{meeting.title} " \
                    "#{ApplicationController.helpers.format_time(meeting.start_time)}",
        normalize_ws: true
      )
      expect(header).to have_no_css(".op-border-box-list-header--description")
    end
  end
end
