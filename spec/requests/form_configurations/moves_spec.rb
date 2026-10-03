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

RSpec.describe "Moving form configuration groups and attributes", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  let(:form) { create(:form_configuration) }
  let!(:details) { create(:form_configuration_group, form_configuration: form, label: "Details") }
  let!(:other) { create(:form_configuration_group, form_configuration: form, label: "Other") }
  let!(:assignee) { membership("assignee", details, 1) }
  let!(:priority) { membership("priority", details, 2) }
  let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  current_user { admin }

  def membership(key, group = nil, position = nil)
    create(:form_configuration_attribute, form_configuration: form, group:, position:, attribute_key: key)
  end

  def group_order = form.form_groups.reload.map(&:label)
  def members(group) = group.members.reload.map(&:key)

  describe "PUT /forms/:id/groups/:id/move" do
    def move_group(group, params)
      put(move_form_configuration_group_path(form, group), params:, headers:)
    end

    it "moves the group and morphs the main content", :aggregate_failures do
      move_group(other, list_type: "group", prev_id: "")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('method="morph"')
      expect(group_order).to eq(%w[Other Details])
    end

    {
      "a wrong list type" => { list_type: "attribute", prev_id: "" },
      "a list id" => { list_type: "group", list_id: "1", prev_id: "" },
      "no anchor key" => { list_type: "group" },
      "a collection anchor" => { list_type: "group", prev_id: ["1"] },
      "an unknown anchor" => { list_type: "group", prev_id: "999999" }
    }.each do |description, params|
      it "answers 422 for #{description} and moves nothing", :aggregate_failures do
        move_group(other, params)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(I18n.t(:error_invalid_list_move_anchor))
        expect(group_order).to eq(%w[Details Other])
      end
    end

    it "answers 404 for an unknown group" do
      put("/forms/#{form.id}/groups/999999/move", params: { list_type: "group", prev_id: "" }, headers:)

      expect(response).to have_http_status(:not_found)
    end

    it "answers 404 for a group of another form" do
      move_group(create(:form_configuration_group), list_type: "group", prev_id: "")

      expect(response).to have_http_status(:not_found)
    end

    context "when not an administrator" do
      current_user { create(:user) }

      it "is forbidden and moves nothing", :aggregate_failures do
        move_group(other, list_type: "group", prev_id: "")

        expect(response).to have_http_status(:forbidden)
        expect(group_order).to eq(%w[Details Other])
      end
    end
  end

  describe "PUT /forms/:id/attributes/:id/move" do
    def move_attribute(record, params)
      put(move_form_configuration_attribute_path(form, record), params:, headers:)
    end

    it "moves into another group and morphs both lists", :aggregate_failures do
      move_attribute(priority, list_type: "attribute", list_id: other.id.to_s, prev_id: "")

      expect(response).to have_http_status(:ok)
      expect(response.body.scan('method="morph"').size).to eq(2)
      expect(members(other)).to eq(%w[priority])
    end

    it "deactivates into the inactive list", :aggregate_failures do
      move_attribute(priority, list_type: "inactive_attribute")

      expect(response).to have_http_status(:ok)
      expect(priority.reload).not_to be_active
    end

    {
      "a collection destination" => ->(e) { { list_type: "attribute", list_id: [e.other.id.to_s], prev_id: "" } },
      "a collection anchor" => ->(e) { { list_type: "attribute", list_id: e.other.id.to_s, prev_id: ["1"] } },
      "no anchor key" => ->(e) { { list_type: "attribute", list_id: e.other.id.to_s } },
      "a group of another form" => lambda { |e|
        { list_type: "attribute", list_id: e.create(:form_configuration_group).id.to_s, prev_id: "" }
      },
      "an unknown list type" => ->(e) { { list_type: "group", list_id: e.other.id.to_s, prev_id: "" } }
    }.each do |description, params|
      it "answers 422 for #{description} and moves nothing", :aggregate_failures do
        move_attribute(priority, params.call(self))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(members(details)).to eq(%w[assignee priority])
      end
    end

    it "reconciles the form's memberships before moving", :aggregate_failures do
      custom_field = create(:wp_custom_field)
      expect(form.form_attributes.where(custom_field:)).to be_empty

      move_attribute(priority, list_type: "attribute", list_id: other.id.to_s, prev_id: "")

      expect(response).to have_http_status(:ok)
      expect(form.form_attributes.where(custom_field:)).to contain_exactly(an_object_having_attributes(active?: false))
    end

    it "answers 404 for a membership of another form" do
      move_attribute(create(:form_configuration_attribute), list_type: "inactive_attribute")

      expect(response).to have_http_status(:not_found)
    end

    context "with a custom field deleted after the page was loaded" do
      let(:custom_field) { create(:wp_custom_field) }
      let!(:stale) do
        create(:form_configuration_attribute, form_configuration: form, group: details, position: 3, custom_field:)
      end

      before { custom_field.destroy! }

      it "answers 404 when its row is dragged" do
        put("/forms/#{form.id}/attributes/#{stale.id}/move",
            params: { list_type: "attribute", list_id: other.id.to_s, prev_id: "" }, headers:)

        expect(response).to have_http_status(:not_found)
      end

      it "answers 422 when its row is the anchor", :aggregate_failures do
        move_attribute(assignee, list_type: "attribute", list_id: details.id.to_s, prev_id: stale.id.to_s)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(members(details)).to eq(%w[assignee priority])
      end
    end
  end
end
