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

require "rails_helper"

RSpec.describe OpPrimer::QuickFilter::SubHeader, type: :component do
  include QuickFilterHelpers

  let(:query) { build_meeting_query }

  def with_one_quick_filter(**)
    render_inline(described_class.new(**)) do |c|
      c.with_quick_filter { "Quick filter" }
    end
  end

  context "without any quick_filter" do
    it "renders without requiring query" do
      expect { render_inline(described_class.new) }.not_to raise_error
    end

    it "still wires up the filter--filters-form controller on its own" do
      render_inline(described_class.new)

      expect(page).to have_css("[data-controller='filter--filters-form']", visible: :all)
    end

    it "builds the clear-button-id attribute from clear_button_id:" do
      render_inline(described_class.new(clear_button_id: "my-clear-button"))

      expect(page).to have_css(
        "[data-filter--filters-form-clear-button-id-value='my-clear-button']", visible: :all
      )
    end

    it "builds the output-format attribute from output_format:" do
      render_inline(described_class.new(output_format: "json"))

      expect(page).to have_css("[data-filter--filters-form-output-format-value='json']", visible: :all)
    end

    it "builds the turbo-frame-request attribute from turbo_frame_request:" do
      render_inline(described_class.new(turbo_frame_request: "my-frame"))

      expect(page).to have_css(
        "[data-filter--filters-form-turbo-frame-request-value='my-frame']", visible: :all
      )
    end

    it "builds the turbo-stream-request attribute from turbo_stream_request:" do
      render_inline(described_class.new(turbo_stream_request: true))

      expect(page).to have_css("[data-filter--filters-form-turbo-stream-request-value='true']", visible: :all)
    end

    it "builds the url-path-name attribute from url_path_name:" do
      render_inline(described_class.new(url_path_name: "/some/path"))

      expect(page).to have_css(
        "[data-filter--filters-form-url-path-name-value='/some/path']", visible: :all
      )
    end

    it "builds the display-filters attribute from display_filters:" do
      render_inline(described_class.new(display_filters: true))

      expect(page).to have_css("[data-filter--filters-form-display-filters-value='true']", visible: :all)
    end

    it "builds the reset-params attribute from reset_params:" do
      render_inline(described_class.new(reset_params: %w[page all]))

      expect(page).to have_css(
        %([data-filter--filters-form-reset-params-value='#{%w[page all].to_json}']), visible: :all
      )
    end

    it "omits attributes whose keyword argument was not given" do
      render_inline(described_class.new)

      expect(page).to have_no_css("[data-filter--filters-form-output-format-value]", visible: :all)
      expect(page).to have_no_css("[data-filter--filters-form-turbo-frame-request-value]", visible: :all)
      expect(page).to have_no_css("[data-filter--filters-form-turbo-stream-request-value]", visible: :all)
      expect(page).to have_no_css("[data-filter--filters-form-url-path-name-value]", visible: :all)
      expect(page).to have_no_css("[data-filter--filters-form-display-filters-value]", visible: :all)
      expect(page).to have_no_css("[data-filter--filters-form-reset-params-value]", visible: :all)
    end
  end

  context "with a quick_filter and a bottom_pane_component, but no query" do
    it "still raises, since the bottom pane's DOM is not guaranteed to cover every quick_filter" do
      expect do
        render_inline(described_class.new) do |c|
          c.with_quick_filter { "Quick filter" }
          c.with_bottom_pane_component { "Advanced filter form" }
        end
      end.to raise_error(ArgumentError, /query/)
    end
  end

  context "with a quick_filter" do
    context "when query is not provided" do
      it "raises instead of silently dropping other active quick filters" do
        expect { with_one_quick_filter }.to raise_error(ArgumentError, /query/)
      end
    end

    context "when the legacy manual data attribute is provided" do
      it "does not raise" do
        expect do
          with_one_quick_filter(data: { "filter--filters-form-current-filters-value": "[]" })
        end.not_to raise_error
      end
    end

    context "when query is provided" do
      subject(:page) { with_one_quick_filter(query:) }

      it "does not raise" do
        expect { page }.not_to raise_error
      end

      it "forwards the serialized filters to the filter--filters-form Stimulus controller" do
        page
        expected = OpPrimer::QuickFilter.serialize(query.filters).to_json

        expect(page).to have_css(%([data-filter--filters-form-current-filters-value='#{expected}']), visible: :all)
      end

      it "still raises nothing when a bottom_pane_component is also present" do
        expect do
          render_inline(described_class.new(query:)) do |c|
            c.with_quick_filter { "Quick filter" }
            c.with_bottom_pane_component { "Advanced filter form" }
          end
        end.not_to raise_error
      end
    end
  end
end
