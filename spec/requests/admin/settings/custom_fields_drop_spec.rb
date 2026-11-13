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

require "spec_helper"

RSpec.describe "Custom fields drop", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  {
    version: :group,
    group: :version
  }.each do |type, other_type|
    context "for #{type} custom fields" do
      let!(:field_a) { create(:"#{type}_custom_field") }
      let!(:field_b) { create(:"#{type}_custom_field") }

      def drop(field, params)
        put send(:"drop_admin_settings_#{field.class.name.underscore}_path", field),
            params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      def ordered_ids
        field_a.class.where(id: [field_a.id, field_b.id]).order(:position).ids
      end

      it "moves the field below the anchor" do
        drop(field_a, { list_type: "custom_field", list_id: "", prev_id: field_b.id.to_s })

        expect(response).to have_http_status(:no_content)
        expect(ordered_ids).to eq([field_b.id, field_a.id])
      end

      it "moves the field to the top for a blank prev_id" do
        drop(field_b, { list_type: "custom_field", list_id: "", prev_id: "" })

        expect(response).to have_http_status(:no_content)
        expect(ordered_ids).to eq([field_b.id, field_a.id])
      end

      it "422s without mutation for an anchor of another custom field type" do
        drop(field_a, { list_type: "custom_field", list_id: "", prev_id: create(:"#{other_type}_custom_field").id.to_s })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(ordered_ids).to eq([field_a.id, field_b.id])
      end

      it_behaves_like "a sortable list drop endpoint", list_id_scoped: false do
        let(:dragged_id) { field_a.id }
        let(:valid_drop_params) { { list_type: "custom_field", list_id: "", prev_id: field_b.id.to_s } }

        def send_drop(params) = drop(field_a, params)

        def expect_unmoved = expect(ordered_ids).to eq([field_a.id, field_b.id])
      end
    end
  end
end
