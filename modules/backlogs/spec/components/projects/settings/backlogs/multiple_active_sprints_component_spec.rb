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

RSpec.describe Projects::Settings::Backlogs::MultipleActiveSprintsComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:user) { create(:admin) }
  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(project:)) }

  context "when sprint sharing is disabled" do
    let(:project) { create(:project, sprint_sharing: "no_sharing") }

    it "renders the toggle switch" do
      expect(rendered_component).to have_css("toggle-switch")
    end

    it "does not render the not-available message" do
      expect(rendered_component).to have_no_text("not available")
    end

    context "when allow_multiple_active_sprints is disabled" do
      it "renders the toggle unchecked" do
        expect(rendered_component).to have_no_css(".ToggleSwitch--checked")
      end

      it "renders the toggle enabled" do
        expect(rendered_component).to have_no_css(".ToggleSwitch--disabled")
      end
    end

    context "when allow_multiple_active_sprints is enabled" do
      let(:project) { create(:project, sprint_sharing: "no_sharing", allow_multiple_active_sprints: true) }

      context "with only one active sprint" do
        before { create(:sprint, project:, status: "active", start_date: Time.zone.today - 1, finish_date: Time.zone.today + 1) }

        it "renders the toggle checked" do
          expect(rendered_component).to have_css(".ToggleSwitch--checked")
        end

        it "renders the toggle enabled" do
          expect(rendered_component).to have_no_css(".ToggleSwitch--disabled")
        end

        it "does not render the too-many-active-sprints warning" do
          expect(rendered_component).to have_no_text(
            I18n.t("projects.settings.backlogs.multiple_active_sprints_component.cannot_turn_off")
          )
        end
      end

      context "with multiple active sprints" do
        before do
          create(:sprint, project:, status: "active", start_date: Time.zone.today - 1, finish_date: Time.zone.today + 1)
          create(:sprint, project:, status: "active", start_date: Time.zone.today - 1, finish_date: Time.zone.today + 1)
        end

        it "renders the toggle checked" do
          expect(rendered_component).to have_css(".ToggleSwitch--checked")
        end

        it "renders the toggle disabled" do
          expect(rendered_component).to have_css(".ToggleSwitch--disabled")
        end

        it "renders the too-many-active-sprints warning" do
          expect(rendered_component).to have_text(
            I18n.t("projects.settings.backlogs.multiple_active_sprints_component.cannot_turn_off")
          )
        end
      end
    end
  end

  context "when sprint sharing is enabled" do
    let(:project) { create(:project, sprint_sharing: "receive_shared") }

    it "does not render the toggle switch" do
      expect(rendered_component).to have_no_css("toggle-switch")
    end

    it "renders the not-available message" do
      expect(rendered_component).to have_text("not available", normalize_ws: true)
    end

    it "renders a link to the sprint sharing settings" do
      expect(rendered_component).to have_link("sprint sharing", href: project_settings_backlog_sharing_path(project))
    end
  end
end
