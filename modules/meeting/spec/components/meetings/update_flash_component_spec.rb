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

require "rails_helper"

RSpec.describe Meetings::UpdateFlashComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:meeting) { create(:meeting, project:) }

  it "marks the reload action as the flash focus target" do
    render_inline(described_class.new(meeting))

    expect(page).to have_link(I18n.t("label_meeting_reload"), href: project_meeting_path(project, meeting))
    expect(page).to have_css("a[data-flash-focus-action='true']", text: I18n.t("label_meeting_reload"))
  end
end
