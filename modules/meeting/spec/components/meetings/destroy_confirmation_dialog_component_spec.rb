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

RSpec.describe Meetings::DeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(meeting:))
    page
  end

  before do
    login_as(user)
  end

  describe "dialog form" do
    let(:meeting) { build_stubbed(:meeting, project:) }

    let(:project) { build_stubbed(:project) }

    it "renders the correct form action" do
      expect(subject).to have_element "form", action: project_meeting_path(project, meeting)
    end
  end

  describe "with a one-time meeting" do
    let(:meeting) { build_stubbed(:meeting, project:) }

    it "shows a heading" do
      expect(subject).to have_text "Delete this meeting?"
    end

    it "shows a simple confirmation message" do
      expect(subject).to have_text "This action is not reversible. Please proceed with caution."
    end
  end

  context "with an associated recurring/templated meeting" do
    let(:series) { build_stubbed(:recurring_meeting) }
    let(:meeting) { build_stubbed(:meeting_template, recurring_meeting: series) }

    it "shows a heading" do
      expect(subject).to have_text "Cancel this meeting occurrence?"
    end

    it "shows a warning about potential information loss" do
      expect(subject).to have_text "Any meeting information not in the template will be lost."
    end
  end

  context "with a past recurring occurrence" do
    let(:series) { build_stubbed(:recurring_meeting, project:) }
    let(:meeting) do
      build_stubbed(:meeting, recurring_meeting: series, project:,
                              start_time: 2.days.ago, duration: 1)
    end

    it "shows the delete heading" do
      expect(subject).to have_text "Delete this occurrence?"
    end

    it "shows a warning saying it is not reversible" do
      expect(subject).to have_text "This action is not reversible. Please proceed with caution."
    end
  end
end
