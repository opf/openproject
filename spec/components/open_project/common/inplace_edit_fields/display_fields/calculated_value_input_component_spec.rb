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

RSpec.describe OpenProject::Common::InplaceEditFields::DisplayFields::CalculatedValueInputComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project, name: "42") }

  it "never attaches the inplace-edit Stimulus controller, even when writable is passed" do
    render_inline(
      described_class.new(model: project, attribute: :name, writable: true, truncated: false, id: "cf-42")
    )

    expect(rendered_content).not_to include("click->inplace-edit#request")
    expect(rendered_content).to have_no_css(".op-inplace-edit--display-field_clickable")
  end

  it "renders the not-editable tooltip" do
    render_inline(
      described_class.new(model: project, attribute: :name, writable: false, truncated: false, id: "cf-42")
    )

    expect(rendered_content).to have_text(I18n.t("custom_fields.calculated_field_not_editable"))
  end
end
