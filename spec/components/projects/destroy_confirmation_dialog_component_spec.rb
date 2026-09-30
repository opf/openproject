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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Projects::DeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project, name: "Top Secret Project") }
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(project:))
    page
  end

  before do
    login_as(user)
  end

  describe "dialog form" do
    let(:project) { build_stubbed(:project) }

    it "renders the correct form action" do
      expect(subject).to have_element "form", action: project_path(project)
    end
  end

  describe "with a project" do
    it "shows a heading" do
      expect(subject).to have_text "Permanently delete this project?"
    end

    it "shows a simple info message" do
      expect(subject).to have_text "You are about to permanently delete all data relating to project Top Secret Project."
    end
  end
end
