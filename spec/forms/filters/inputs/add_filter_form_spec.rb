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

RSpec.describe Filters::Inputs::AddFilterForm, type: :forms do
  include ViewComponent::TestHelpers

  let(:query) { UserQuery.new }
  let(:allowed_filters) { query.available_advanced_filters }
  let(:active_filter_names) { [] }

  def render_add_filter_form(allowed_filters: self.allowed_filters,
                             active_filter_names: self.active_filter_names)
    form_class = described_class
    render_in_view_context(form_class, allowed_filters, active_filter_names) do |form_class, allowed_filters, active_filter_names|
      primer_form_with(url: "/test", method: :post) do |f|
        render(form_class.new(f, allowed_filters:, active_filter_names:))
      end
    end
  end

  subject(:rendered_form) do
    render_add_filter_form
    page
  end

  it "renders a select named add_filter_select" do
    expect(rendered_form).to have_select "add_filter_select"
  end

  it "has the addFilterSelect Stimulus target" do
    expect(rendered_form).to have_element :select,
                                          "data-filter--filters-form-target": "addFilterSelect"
  end

  it "includes a blank prompt option" do
    select = rendered_form.find(:select, "add_filter_select")
    expect(select).to have_selector :option, text: I18n.t(:actionview_instancetag_blank_option)
  end

  it "lists all allowed filters as options" do
    expect(rendered_form).to have_select "add_filter_select" do |select|
      allowed_filters.each do |af|
        expect(select).to have_selector :option, text: af.human_name
      end
    end
  end

  context "with active filters" do
    let(:active_filter_names) { [:login] }

    it "disables the active filter option" do
      select = rendered_form.find(:select, "add_filter_select")
      login_option = select.find(:option, text: "Username")
      expect(login_option).to be_disabled
    end

    it "does not disable inactive filter options" do
      select = rendered_form.find(:select, "add_filter_select")
      status_option = select.find(:option, text: "Status")
      expect(status_option).not_to be_disabled
    end
  end
end
