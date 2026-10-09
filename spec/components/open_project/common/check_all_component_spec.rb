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

RSpec.describe OpenProject::Common::CheckAllComponent, type: :component do
  def render_component(**, &)
    render_inline(described_class.new(**), &)
  end

  shared_examples "rendering Link-style buttons" do
    it "renders Link-style buttons", :aggregate_failures do
      expect(rendered_component).to have_button count: 2
      expect(rendered_component).to have_button "Check all", class: "Button--link"
      expect(rendered_component).to have_button "Uncheck all", class: "Button--link"
    end
  end

  context "when :checkable_id is present" do
    subject(:rendered_component) do
      render_component(checkable_id: "foo")
    end

    include_examples "rendering Link-style buttons"

    it "registers Stimulus controller and defines outlets" do
      expect(rendered_component).to have_element :span do |form|
        expect(form["data-controller"]).to include "check-all"
        expect(form["data-check-all-checkable-outlet"]).to include "#foo [data-controller~='checkable']"
      end
    end

    it "connects Stimulus controller actions for 'Check all'" do
      expect(rendered_component).to have_button "Check all" do |button|
        expect(button["data-action"]).to include "check-all#checkAll:stop"
      end
    end

    it "connects Stimulus controller actions for 'Uncheck all'" do
      expect(rendered_component).to have_button "Uncheck all" do |button|
        expect(button["data-action"]).to include "check-all#uncheckAll:stop"
      end
    end

    it "sets aria-controls attribute on 'Check all'" do
      expect(rendered_component).to have_button "Check all", aria: { controls: "foo" }
    end

    it "sets aria-controls attribute on 'Uncheck all'" do
      expect(rendered_component).to have_button "Uncheck all", aria: { controls: "foo" }
    end

    it "applies an ID to 'Check all'" do
      expect(subject).to have_button id: "foo-check-all"
    end

    it "applies an ID to 'Uncheck all'" do
      expect(subject).to have_button id: "foo-uncheck-all"
    end
  end

  context "when :checkable_id is nil" do
    subject(:rendered_component) do
      render_component
    end

    include_examples "rendering Link-style buttons"

    it "does not register Stimulus controller" do
      expect(rendered_component).to have_element :span do |form|
        expect(form["data-controller"]).to be_blank
      end
    end

    it "connects Stimulus controller actions for 'Check all'" do
      expect(rendered_component).to have_button "Check all" do |button|
        expect(button["data-action"]).to include "checkable#checkAll:stop"
      end
    end

    it "connects Stimulus controller actions for 'Uncheck all'" do
      expect(rendered_component).to have_button "Uncheck all" do |button|
        expect(button["data-action"]).to include "checkable#uncheckAll:stop"
      end
    end

    it "does not set aria-controls attribute on 'Check all'" do
      expect(rendered_component).to have_button "Check all" do |button|
        expect(button["aria-controls"]).to be_nil
      end
    end

    it "does not set aria-controls attribute on 'Uncheck all'" do
      expect(rendered_component).to have_button "Uncheck all" do |button|
        expect(button["aria-controls"]).to be_nil
      end
    end

    it "applies an ID to 'Check all'" do
      expect(subject).to have_button id: /check-all-component-([\w-]+)-check-all/
    end

    it "applies an ID to 'Uncheck all'" do
      expect(subject).to have_button id: /check-all-component-([\w-]+)-uncheck-all/
    end
  end

  context "with button slots" do
    subject(:rendered_component) do
      render_component do |check_all|
        check_all.with_check_all_button(scheme: :primary) do
          "Select all"
        end
        check_all.with_uncheck_all_button(scheme: :danger) do
          "Unselect all"
        end
      end
    end

    it "renders custom buttons", :aggregate_failures do
      expect(rendered_component).to have_button count: 2
      expect(rendered_component).to have_button "Select all", class: "Button--primary"
      expect(rendered_component).to have_button "Unselect all", class: "Button--danger"
    end
  end

  context "with separator slot" do
    subject(:rendered_component) do
      render_component do |check_all|
        check_all.with_separator do
          "♾️"
        end
      end
    end

    it "renders custom separator" do
      expect(rendered_component).to have_content "♾️"
    end
  end
end
