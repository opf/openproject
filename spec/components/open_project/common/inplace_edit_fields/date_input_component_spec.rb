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

RSpec.describe OpenProject::Common::InplaceEditFields::DateInputComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project) }

  it "renders a date input for the attribute with Stimulus controller attached" do
    component_class = described_class
    render_in_view_context(project) do |model|
      primer_form_with(url: "/foo", model:) do |f|
        render_inline_form(f) do |form|
          render component_class.new(form:, model:, attribute: :name, label: "Name")
        end
      end
    end

    expect(rendered_content).to have_field("project[name]", type: "date")
    expect(rendered_content).to include("change-&gt;inplace-edit#submitForm")
  end

  it "does not add a submit-on-change Stimulus action whe show_action_buttons is false" do
    component_class = described_class
    render_in_view_context(project) do |model|
      primer_form_with(url: "/foo", model:) do |f|
        render_inline_form(f) do |form|
          render component_class.new(form:, model:, attribute: :name, label: "Name", show_action_buttons: false)
        end
      end
    end

    expect(rendered_content).not_to include("change-&gt;inplace-edit#submitForm")
  end
end
