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

RSpec.describe Filters::Inputs::ListForm, type: :forms do
  include_context "with rendered filter input form"

  let(:query) { UserQuery.new }
  let(:filter) { query.available_advanced_filters.find { |af| af.name == :status } }

  it_behaves_like "rendering filter row"
  it_behaves_like "rendering operator select"
  it_behaves_like "hidden when inactive"

  it "renders an autocompleter component" do
    expect(rendered_form).to have_element "opce-autocompleter", visible: :all
  end

  it "marks the autocompleter as multiple" do
    expect(rendered_form).to have_element "opce-autocompleter",
                                          "data-multiple": "true",
                                          visible: :all
  end

  it "sets data-filter-autocomplete on the wrapper" do
    expect(rendered_form).to have_element "data-filter-name": "status",
                                          "data-filter-autocomplete": "true",
                                          visible: :all
  end

  context "with additional autocomplete options" do
    let(:additional_attributes) { { autocomplete_options: { appendTo: "#dialog" } } }

    it "merges the appendTo option into the autocompleter" do
      autocompleter = rendered_form.find(:element, "opce-autocompleter", visible: :all)
      expect(autocompleter["data-append-to"]).to be_json_eql(%("#dialog"))
    end
  end
end
