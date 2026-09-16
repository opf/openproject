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

RSpec.describe Admin::Labels::ListComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:admin) { create(:admin) }

  subject(:rendered_component) do
    with_request_url "/admin/labels" do
      render_inline(described_class.new(labels, query:))
    end
  end

  context "with labels" do
    shared_let(:used) { create(:label, name: "Bug") }
    shared_let(:unused) { create(:label, name: "Feature") }
    shared_let(:labelings) { create_list(:labeling, 2, label: used) }

    let(:labels) { Label.with_usage_count.order(:name).paginate(page: 1, per_page: 10) }
    let(:query) { Queries::Labels::LabelQuery.new }

    it "renders the column captions" do
      rendered_component

      expect(page).to have_css(".Box-header", text: "Label")
      expect(page).to have_css(".Box-header", text: "Used in")
    end

    it "renders one row per label" do
      rendered_component

      expect(page).to have_css("[data-test-selector='label-row-#{used.id}']")
      expect(page).to have_css("[data-test-selector='label-row-#{unused.id}']")
    end

    it "renders the usage count for a used label and a dash for an unused one" do
      rendered_component

      used_row = page.find("[data-test-selector='label-row-#{used.id}']")
      expect(used_row).to have_css("[data-test-selector='label-usage']", text: "2 work packages")

      unused_row = page.find("[data-test-selector='label-row-#{unused.id}']")
      expect(unused_row).to have_css("[data-test-selector='label-usage']", text: "-")
    end

    it "renders a pagination footer" do
      rendered_component

      expect(page).to have_css(".op-pagination")
    end
  end

  context "without labels" do
    let(:labels) { Label.with_usage_count.paginate(page: 1, per_page: 10) }

    context "with no active filter" do
      let(:query) { Queries::Labels::LabelQuery.new }

      it_behaves_like "rendering Blank Slate",
                      heading: I18n.t("admin.labels.list_component.blank_slate.title"),
                      icon: :tag
    end

    context "with a name filter matching nothing" do
      let(:query) do
        ParamsToQueryService
          .new(Label, admin, query_class: Queries::Labels::LabelQuery)
          .call(ActionController::Parameters.new(filters: [{ name: { operator: "~", values: ["zzz"] } }].to_json))
      end

      it_behaves_like "rendering Blank Slate",
                      heading: I18n.t("admin.labels.list_component.no_matches.title"),
                      icon: :search

      it "renders the no-matches description" do
        rendered_component

        expect(page).to have_text(I18n.t("admin.labels.list_component.no_matches.description"))
      end
    end
  end
end
