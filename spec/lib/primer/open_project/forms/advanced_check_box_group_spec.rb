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
#
require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::AdvancedCheckBoxGroup, type: :forms do
  include ViewComponent::TestHelpers

  describe "rendering" do
    let(:params) { {} }
    let(:model) { build_stubbed(:comment) }

    def render_form
      render_in_view_context(model, params) do |model, params|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |check_form|
            check_form.advanced_check_box_group(
              name: :ultimate_answer,
              label: "Ultimate answer",
              **params
            ) do |group|
              group.check_box(
                value: "one",
                label: "One",
                caption: "Pick me",
                trailing_image: "icon_logo.svg"
              )
              group.check_box(
                value: "two",
                label: "Two",
                caption: "Don't pick me",
                trailing_image: "icon_logo.svg"
              )
              group.check_box(
                value: "three",
                label: "Three",
                trailing_image: nil
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

    it "renders the fieldset" do
      expect(rendered_form).to have_selector :fieldset, "Ultimate answer"
    end

    it "renders the checkboxes", :aggregate_failures do
      expect(rendered_form).to have_field "One", type: :checkbox, fieldset: "Ultimate answer"
      expect(rendered_form).to have_field "Two", type: :checkbox, fieldset: "Ultimate answer"
      expect(rendered_form).to have_field "Three", type: :checkbox, fieldset: "Ultimate answer"
    end

    it "renders icons" do
      expect(rendered_form).to have_element :svg, count: 2, aria: { hidden: true }
    end

    it "puts a leading icon before the label" do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |check_form|
            check_form.advanced_check_box_group(name: :foobar, label: "Foobar") do |group|
              group.check_box(value: "one", label: "One", leading_icon: :"git-branch")
            end
          end
        end
      end

      expect(page).to have_css ".FormControl-advanced-checkbox-label-text .octicon-git-branch"
    end

    it "renders captions", :aggregate_failures do
      expect(rendered_form).to have_css ".FormControl-caption", count: 2
      expect(rendered_form).to have_css ".FormControl-caption", text: "Pick me"
      expect(rendered_form).to have_css ".FormControl-caption", text: "Don't pick me"
    end
  end

  describe "standard checkbox group compatibility" do
    specify "hidden checkbox group", :aggregate_failures do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |check_form|
            check_form.advanced_check_box_group(label: "Foobar", hidden: true) do |check_group|
              check_group.check_box(name: :foo, label: "Foo")
            end
          end
        end
      end

      expect(page).to have_selector :fieldset, visible: :hidden
      expect(page).to have_css ".FormControl-advanced-checkbox-wrap", visible: :hidden
    end

    specify "disabled checkbox group disables constituent checkboxes" do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |check_form|
            check_form.advanced_check_box_group(label: "Foobar", disabled: true) do |check_group|
              check_group.check_box(name: :foo, label: "Foo")
            end
          end
        end
      end

      expect(page).to have_css ".FormControl-advanced-checkbox-wrap input[disabled]"
    end

    specify "checkbox can be individually disabled in group" do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |check_form|
            check_form.advanced_check_box_group(label: "Foobar") do |check_group|
              check_group.check_box(name: :foo, label: "Foo", disabled: true)
            end
          end
        end
      end

      expect(page).to have_css ".FormControl-advanced-checkbox-wrap input[disabled]"
    end
  end
end
