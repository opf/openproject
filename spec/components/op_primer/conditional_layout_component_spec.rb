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

RSpec.describe OpPrimer::ConditionalLayoutComponent, type: :component do
  def render_component(*, **, &)
    render_inline(described_class.new(*, **), &)
  end

  let(:sidebar_content) { "sidebar" }
  let(:main_content) { "content" }

  subject(:rendered_component) do
    render_component(condition:, fallback_component_args: { classes: "op-fallback" }) do |component|
      component.with_sidebar do
        sidebar_content
      end

      main_content
    end
  end

  context "when content is empty" do
    let(:condition) { false }
    let(:main_content) { "" }

    it "renders content in fallback" do
      expect(rendered_component).to have_css ".op-fallback", text: ""
    end
  end

  context "when condition is false" do
    let(:condition) { false }

    it "does not render layout" do
      expect(rendered_component).to have_no_css ".Layout"
    end

    it "renders content in fallback" do
      expect(rendered_component).to have_css ".op-fallback", text: "content"
    end

    it "does not render sidebar" do
      expect(rendered_component).to have_no_css ".Layout-sidebar"
    end
  end

  context "when condition is true" do
    let(:condition) { true }

    it "renders layout" do
      expect(rendered_component).to have_css ".Layout"
    end

    it "renders content in main" do
      expect(rendered_component).to have_css ".Layout-main", text: "content"
    end

    it "renders sidebar" do
      expect(rendered_component).to have_css ".Layout-sidebar"
    end
  end
end
