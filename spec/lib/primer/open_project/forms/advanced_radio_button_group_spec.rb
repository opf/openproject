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

RSpec.describe Primer::OpenProject::Forms::AdvancedRadioButtonGroup, type: :forms do
  include ViewComponent::TestHelpers

  describe "rendering" do
    let(:params) { {} }
    let(:model) { build_stubbed(:comment) }

    def render_form
      render_in_view_context(model, params) do |model, params|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |radio_form|
            radio_form.advanced_radio_button_group(
              name: :ultimate_answer,
              label: "Ultimate answer",
              **params
            ) do |group|
              group.radio_button(
                value: "one",
                label: "One",
                caption: "Pick me",
                trailing_image: "icon_logo.svg"
              )
              group.radio_button(
                value: "two",
                label: "Two",
                caption: "Don't pick me",
                trailing_image: "icon_logo.svg"
              )
              group.radio_button(
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
      expect(rendered_form).to have_selector :fieldset, "Ultimate answer", role: "radiogroup"
    end

    it "renders the radio buttons", :aggregate_failures do
      expect(rendered_form).to have_field "One", type: :radio, fieldset: "Ultimate answer"
      expect(rendered_form).to have_field "Two", type: :radio, fieldset: "Ultimate answer"
      expect(rendered_form).to have_field "Three", type: :radio, fieldset: "Ultimate answer"
    end

    it "renders trailing images" do
      expect(rendered_form).to have_element :svg, count: 2, aria: { hidden: true }
    end

    it "renders captions", :aggregate_failures do
      expect(rendered_form).to have_css ".FormControl-caption", count: 2
      expect(rendered_form).to have_css ".FormControl-caption", text: "Pick me"
      expect(rendered_form).to have_css ".FormControl-caption", text: "Don't pick me"
    end
  end

  describe "the slots an option may carry" do
    def render_options(&)
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |radio_form|
            radio_form.advanced_radio_button_group(name: :foobar, label: "Foobar", &)
          end
        end
      end
    end

    it "puts a leading icon before the label" do
      render_options do |group|
        group.radio_button(value: "Foo", label: "Foo", leading_icon: :"git-branch")
      end

      expect(page).to have_css ".FormControl-advanced-radio-label-text .octicon-git-branch"
    end

    it "names a source after the label" do
      render_options do |group|
        group.radio_button(value: "Foo", label: "Foo", title_link: { text: "Bug", href: "/types/1" })
      end

      expect(page).to have_link "Bug", href: "/types/1"
    end

    it "offers the action of the option in force, and of no other" do
      render_options do |group|
        group.radio_button(value: "Foo", label: "Foo", checked: true,
                           action: { text: "Change source", href: "/change" })
        group.radio_button(value: "Bar", label: "Bar", action: { text: "Not offered", href: "/nope" })
      end

      expect(page).to have_link "Change source", href: "/change"
      expect(page).to have_no_link "Not offered"
    end

    it "renders nested content outside the label, so using it cannot select the option" do
      nested = Class.new(ApplicationForm) do
        form { |f| f.text_field(name: :street_name, label: "Street", visually_hide_label: true) }
      end

      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |radio_form|
            radio_form.advanced_radio_button_group(name: :foobar, label: "Foobar") do |group|
              group.radio_button(value: "Foo", label: "Foo", nested_content: nested.new(f))
            end
          end
        end
      end

      expect(page).to have_css ".FormControl-advanced-radio-wrap--stacked"
      expect(page).to have_css ".FormControl-advanced-radio-nested input[name='street_name']"
      expect(page).to have_no_css "label .FormControl-advanced-radio-nested"
    end

    it "leaves the card unstacked when nothing is nested in it" do
      render_options do |group|
        group.radio_button(value: "Foo", label: "Foo")
      end

      expect(page).to have_css ".FormControl-advanced-radio-wrap"
      expect(page).to have_no_css ".FormControl-advanced-radio-wrap--stacked"
    end
  end

  describe "standard radio button group compatibility" do
    specify "hidden radio button group", :aggregate_failures do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |radio_form|
            radio_form.advanced_radio_button_group(name: :foobar, label: "Foobar", hidden: true) do |radio_group|
              radio_group.radio_button(value: "Foo", label: "Foo")
            end
          end
        end
      end

      expect(page).to have_selector :fieldset, visible: :hidden
      expect(page).to have_css ".FormControl-advanced-radio-wrap", visible: :hidden
    end

    specify "disabled radio group disables constituent radios" do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |radio_form|
            radio_form.advanced_radio_button_group(name: :foobar, label: "Foobar", disabled: true) do |radio_group|
              radio_group.radio_button(value: "Foo", label: "Foo")
            end
          end
        end
      end

      expect(page).to have_css ".FormControl-advanced-radio-wrap input[disabled]"
    end

    specify "radio can be individually disabled in group" do
      render_in_view_context do
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |radio_form|
            radio_form.advanced_radio_button_group(name: :foobar, label: "Foobar") do |radio_group|
              radio_group.radio_button(value: "Foo", label: "Foo", disabled: true)
            end
          end
        end
      end

      expect(page).to have_css ".FormControl-advanced-radio-wrap input[disabled]"
    end
  end
end
