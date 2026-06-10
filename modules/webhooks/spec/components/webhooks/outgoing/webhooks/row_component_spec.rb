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

RSpec.describe Webhooks::Outgoing::Webhooks::RowComponent, type: :component do
  subject(:rendered_component) do
    table = instance_double(Webhooks::Outgoing::Webhooks::TableComponent,
                            columns: [column],
                            target_controller: "webhooks/outgoing/admin")
    render_inline(described_class.new(row: webhook, table:))
  end

  describe "Name" do
    let(:webhook) { build_stubbed(:webhook, name: "Hook me up") }
    let(:column) { :name }

    it "renders name" do
      expect(rendered_component).to have_content "Hook me up"
    end
  end

  describe "Enabled Projects" do
    let(:column) { :selected_projects }

    context "when all projects enabled" do
      let(:webhook) { build_stubbed(:webhook, all_projects: true) }

      it "renders 'All projects'" do
        expect(rendered_component).to have_content "All projects"
      end
    end

    context "when some projects are enabled" do
      let(:webhook) { create(:webhook, all_projects: false, projects: create_list(:project, 2)) }

      it "renders 'X projects'" do
        expect(rendered_component).to have_content "2 projects"
      end
    end

    context "when no projects are enabled" do
      let(:webhook) { build_stubbed(:webhook, all_projects: false) }

      it "renders 'No projects'" do
        expect(rendered_component).to have_octicon :alert
        expect(rendered_component).to have_content "No projects"
      end
    end
  end

  describe "Events" do
    let(:column) { :events }
    let(:webhook) { create(:webhook, event_names:) }

    context "when no events are enabled" do
      let(:event_names) { [] }

      it "renders 'No events'" do
        expect(rendered_component).to have_octicon :alert
        expect(rendered_component).to have_content "No events"
      end
    end

    context "when some events are enabled" do
      let(:event_names) { ["project:created", "work_package_comment:comment"] }

      it "renders events list grouped by Resource", :aggregate_failures do
        expect(rendered_component).to have_list do |list|
          expect(list).to have_list_item count: 2
          expect(list).to have_list_item "Projects (Created)"
          expect(list).to have_list_item "Work package comments (Comment)"
        end
      end
    end
  end
end
