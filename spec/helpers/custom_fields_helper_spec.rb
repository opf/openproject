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

RSpec.describe CustomFieldsHelper do
  describe "#custom_field_tag_for_bulk_edit" do
    context "with a datetime custom field" do
      let(:custom_field) { build_stubbed(:wp_custom_field, :datetime) }
      let(:value) { nil }
      let(:field_name) { "work_package[custom_field_values][#{custom_field.id}]" }

      current_user { build_stubbed(:user, preferences: { time_zone: "Europe/Berlin" }) }

      subject(:rendered) do
        Capybara.string(helper.custom_field_tag_for_bulk_edit("work_package", custom_field, nil, value))
      end

      it "renders an empty local field without a value" do
        expect(rendered).to have_field "work_package_custom_field_values_#{custom_field.id}",
                                       type: "datetime-local", with: ""
      end

      it "keeps the local field out of the submitted custom field values" do
        expect(rendered).to have_field "work_package_custom_field_values_#{custom_field.id}_local",
                                       type: "datetime-local"
      end

      it "renders an empty submitted value without a value" do
        expect(rendered).to have_field field_name, type: :hidden, with: ""
      end

      it "wires up the Stimulus controller" do
        expect(rendered).to have_css "input[data-controller='custom-fields--datetime-input']"
      end

      context "with a submitted value" do
        let(:value) { "2026-10-01T14:30:00+02:00" }

        it "renders the local field in the user's time zone" do
          expect(rendered).to have_field "work_package_custom_field_values_#{custom_field.id}",
                                         type: "datetime-local", with: "2026-10-01T14:30"
        end

        it "keeps the submitted value" do
          expect(rendered).to have_field field_name, type: :hidden, with: value
        end
      end
    end
  end
end
