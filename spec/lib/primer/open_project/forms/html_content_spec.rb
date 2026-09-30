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

RSpec.describe Primer::OpenProject::Forms::HtmlContent, type: :forms do
  include ViewComponent::TestHelpers

  let(:model) { build_stubbed(:comment) }

  def render_form_in_view_context(&)
    render_in_view_context(model) do |model|
      primer_form_with(url: "/foo", model:) do |f|
        render_inline_form(f, &)
      end
    end
  end

  context "with plain text" do
    subject(:rendered_form) do
      render_form_in_view_context do |f|
        f.html_content do
          "Hallo Welt"
        end
      end
      page
    end

    it "renders the text" do
      expect(rendered_form).to have_content "Hallo Welt"
    end
  end

  context "with Rails helpers" do
    subject(:rendered_form) do
      render_form_in_view_context do |f|
        f.html_content do
          content_tag(:p, "Hallo Welt")
        end
      end
      page
    end

    it "renders the HTML" do
      expect(rendered_form).to have_element :p, text: "Hallo Welt"
    end
  end

  context "with other view components" do
    subject(:rendered_form) do
      render_form_in_view_context do |f|
        f.html_content do
          render(Primer::Beta::Text.new(tag: :p, font_weight: :bold)) { "Hallo Welt" }
        end
      end
      page
    end

    it "renders the HTML" do
      expect(rendered_form).to have_element :p, text: "Hallo Welt"
    end
  end
end
