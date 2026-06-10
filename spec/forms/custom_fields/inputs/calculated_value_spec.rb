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

RSpec.describe CustomFields::Inputs::CalculatedValue, type: :forms, with_ee: %i[calculated_values] do
  include_context "with rendered custom field input form"

  let(:custom_field) { create(:calculated_value_project_custom_field, name: "Calculated value field", formula: "1 + 1") }

  it_behaves_like "rendering label with help text", "Calculated value field"

  context "without a value" do
    it "renders field" do
      expect(rendered_form).to have_field "Calculated value field", type: :number, disabled: true, with: ""
    end
  end

  context "with a value" do
    let(:value) { 78.23 }

    it "renders field" do
      expect(rendered_form).to have_field "Calculated value field", type: :number, disabled: true, with: "78.23"
    end
  end
end
