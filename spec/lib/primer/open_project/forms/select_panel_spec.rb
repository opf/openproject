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
#
require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::SelectPanel, type: :forms do
  include ViewComponent::TestHelpers

  describe "rendering" do
    let(:params) { {} }
    let(:model) { build_stubbed(:comment) }

    def render_form
      render_in_view_context(model, params) do |model, params|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.select_panel(
              name: :ultimate_answer,
              label: "Ultimate answer",
              **params
            ) do |panel|
              panel.with_item(
                label: "One",
                content_arguments: { data: { value: "one" } },
                active: true,
                item_id: "type-one"
              )
              panel.with_item(
                label: "Two",
                content_arguments: { data: { value: "two" } },
                item_id: "answer-two"
              )
            end
          end
        end
      end
    end

    subject(:rendered_form) do
      render_form
      page
    end

    it "renders the label" do
      expect(rendered_form).to have_element :label
    end

    it "renders the select-panel" do
      expect(rendered_form).to have_element :"select-panel"
    end

    it "renders the buttons", :aggregate_failures do
      expect(rendered_form).to have_button "One", role: "option", aria: { selected: true }
      expect(rendered_form).to have_button "Two", role: "option"
    end
  end
end
