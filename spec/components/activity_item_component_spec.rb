# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require "rails_helper"

RSpec.describe ActivityItemComponent, type: :component do
  let(:event) do
    Activities::Event.new(
      event_title: "Event Title",
      event_description: "something",
      event_datetime: journal.created_at,
      project_id: project.id,
      project:,
      event_path: "/project/123"
    )
  end
  let(:project) { build_stubbed(:project) }
  let(:journal) { build_stubbed(:project_journal, journable: project) }

  it 'renders the title escaped' do
    event.event_title = 'Hello <b>World</b>!'
    render_inline(described_class.new(event:, journal:))

    expect(page).to have_css('.op-activity-list--item-title', text: 'Hello <b>World</b>!')
  end
end
