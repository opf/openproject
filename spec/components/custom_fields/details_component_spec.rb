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

RSpec.describe CustomFields::DetailsComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(custom_field)) }

  let(:banner) { I18n.t("custom_fields.admin.notice.remember_items_and_projects") }

  current_user { create(:admin) }

  describe "the reminder banner for a list custom field without options" do
    let(:type) { create(:type) }
    let(:custom_field) { create(:list_wp_custom_field, possible_values: [], types: [type]) }

    context "when no project uses the type carrying it" do
      it "reminds, since the field can appear nowhere" do
        expect(rendered.to_html).to include(banner)
      end
    end

    context "when a project uses the type carrying it" do
      before { create(:project, types: [type]) }

      it "does not remind" do
        expect(rendered.to_html).not_to include(banner)
      end
    end

    context "when the field is on no type at all" do
      let(:custom_field) { create(:list_wp_custom_field, possible_values: []) }

      it "reminds" do
        expect(rendered.to_html).to include(banner)
      end
    end
  end

  describe "for a project custom field" do
    let(:custom_field) { create(:list_project_custom_field, possible_values: []) }

    it "reminds while it is mapped to no project" do
      expect(rendered.to_html).to include(banner)
    end

    context "when mapped to a project" do
      before { create(:project_custom_field_project_mapping, project_custom_field: custom_field) }

      it "does not remind" do
        expect(rendered.to_html).not_to include(banner)
      end
    end
  end
end
