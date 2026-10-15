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

RSpec.describe Admin::Enumerations::IndexComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/admin/settings/work_package_priorities") do
      render_inline(described_class.new(enumerations:))
    end
  end

  context "with enumerations" do
    let!(:priority_a) { create(:priority, name: "Urgent") }
    let!(:priority_b) { create(:priority, name: "Trivial") }
    let(:enumerations) { IssuePriority.where(id: [priority_a.id, priority_b.id]).order(:position) }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box List heading",
                    text: IssuePriority.model_name.human(count: :other),
                    level: 3

    it "renders a row per enumeration", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-row", text: "Urgent")
      expect(rendered_component).to have_css(".Box-row", text: "Trivial")
    end

    it_behaves_like "a sortable-lists root",
                    wrapper_id: "admin-enumerations-index-component",
                    move_url_template: "/admin/settings/work_package_priorities/{id}/move"
    it_behaves_like "a sortable-lists list",
                    list_type: "issue_priority",
                    name: IssuePriority.model_name.human(count: :other)
    it_behaves_like "a Border Box sortable list", row_count: 2
    it_behaves_like "sortable-lists items", list_type: "issue_priority" do
      let(:sortable_records) { [priority_a, priority_b] }
    end
    it_behaves_like "no legacy drag-and-drop wiring"
  end

  context "without enumerations" do
    let(:enumerations) { IssuePriority.where(id: nil) }

    it_behaves_like "rendering an empty Border Box List", heading: I18n.t(:no_results_title_text)
  end
end
