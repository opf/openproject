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

RSpec.describe "Work package type excluded elements",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:source) { create(:type) }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }
  let(:type) { create(:type) }
  let(:link) { variant_of(type) }

  before { login_as admin }

  def toggle(value:, element: "assignee")
    post type_excluded_element_toggle_path(type_id: type.id, aspect:, element:), params: { value: }
  end

  context "when the type is Linked for the aspect" do
    before { link_configuration(type, source:, aspect:) }

    it "excludes the element when switched off", :aggregate_failures do
      toggle(value: "0")

      expect(response).to have_http_status(:ok)
      expect(excluded_configuration_elements(link, aspect: aspect)).to contain_exactly("assignee")
    end

    it "restores the element when switched on", :aggregate_failures do
      exclude_configuration_elements(link, aspect: aspect, elements: %w[assignee custom_field_1])

      toggle(value: "1")

      expect(response).to have_http_status(:ok)
      expect(excluded_configuration_elements(link, aspect: aspect)).to contain_exactly("custom_field_1")
    end

    it "leaves the other aspects alone" do
      link_configuration(type, source:, aspect: TypeVariant::PDF_EXPORT)

      toggle(value: "0")

      expect(excluded_configuration_elements(type, aspect: TypeVariant::PDF_EXPORT))
        .to be_empty
    end
  end

  it "is unprocessable when the type owns the aspect" do
    toggle(value: "0")

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "is not found for an unknown aspect" do
    post type_excluded_element_toggle_path(type_id: type.id, aspect: "not_an_aspect", element: "assignee"),
         params: { value: "0" }

    expect(response).to have_http_status(:not_found)
  end

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
    before { link_configuration(type, source:, aspect:) }

    it "blocks the endpoint and excludes nothing", :aggregate_failures do
      toggle(value: "0")

      expect(response).to have_http_status(:not_found)
      expect(excluded_configuration_elements(link, aspect: aspect)).to be_empty
    end
  end

  context "when the user is not an admin" do
    before { login_as create(:user) }

    it "is forbidden" do
      link_configuration(type, source:, aspect:)

      toggle(value: "0")

      expect(response).to have_http_status(:forbidden)
    end
  end
end
