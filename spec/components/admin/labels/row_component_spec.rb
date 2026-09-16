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

RSpec.describe Admin::Labels::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:query) { Queries::Labels::LabelQuery.new }

  subject(:rendered_component) do
    with_request_url "/admin/labels" do
      render_inline(Admin::Labels::TableComponent.new(rows: [label], query:))
    end
  end

  context "with a used label" do
    shared_let(:record) { create(:label, name: "Bug") }
    shared_let(:labelings) { create_list(:labeling, 3, label: record) }

    let(:label) { Label.with_usage_count.find(record.id) }

    it "renders the name as a chip" do
      expect(rendered_component).to have_css("[data-test-selector='label-name']", text: "Bug")
    end

    it "renders the pluralised usage count" do
      expect(rendered_component).to have_css("[data-test-selector='label-usage']", text: "3 work packages")
    end
  end

  context "with an unused label" do
    shared_let(:record) { create(:label, name: "Feature") }

    let(:label) { Label.with_usage_count.find(record.id) }

    it "renders a dash instead of a count" do
      expect(rendered_component).to have_css("[data-test-selector='label-usage']", text: "-")
    end
  end

  context "with the actions menu" do
    shared_let(:record) { create(:label, name: "Bug") }

    let(:label) { Label.with_usage_count.find(record.id) }

    it "links Rename to the edit dialog as an async-dialog request" do
      expect(rendered_component).to have_css(
        "a[href='#{edit_dialog_admin_label_path(label)}'][data-controller='async-dialog']",
        text: "Rename",
        visible: :all
      )
    end

    it "links Delete to the deletion dialog as a danger, async-dialog request" do
      expect(rendered_component).to have_css(
        "a[href='#{deletion_dialog_admin_label_path(label)}'][data-controller='async-dialog']",
        text: "Delete",
        visible: :all
      )
    end
  end
end
