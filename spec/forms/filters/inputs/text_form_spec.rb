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

RSpec.describe Filters::Inputs::TextForm, type: :forms do
  include_context "with rendered filter input form"

  let(:query) { UserQuery.new }
  let(:filter) do
    f = query.available_advanced_filters.find { |af| af.name == :login }
    f.operator = "~"
    f.values = ["admin"]
    f
  end

  it_behaves_like "rendering filter row"
  it_behaves_like "rendering operator select"
  it_behaves_like "hidden when inactive"

  it "renders a text input with the filter value" do
    expect(rendered_form).to have_field type: :text, with: "admin"
  end

  it "names the input after the filter" do
    expect(rendered_form).to have_element :input, name: "login_value", visible: :all
  end

  context "with a numeric filter" do
    let!(:integer_field) { create(:user_custom_field, :integer) }
    let(:filter) do
      query.available_advanced_filters.find { |af| af.name == :"cf_#{integer_field.id}" }
    end

    it "renders a number input with step" do
      expect(rendered_form).to have_element :input,
                                            type: "number",
                                            step: "any",
                                            visible: :all
    end
  end
end
