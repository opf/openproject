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

RSpec.describe Statuses::IndexComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/statuses") do
      render_inline(described_class.new(statuses:, query:, page_args:))
    end
  end

  let(:page_args) { { page: 1, per_page: 20 } }
  let(:query) { Queries::Statuses::StatusQuery.new(user: User.current) }
  let(:statuses) { Status.all.page(page_args[:page]).per_page(page_args[:per_page]) }

  let!(:new_status) { create(:status, name: "New") }

  # The move action morphs this wrapper, so the id has to survive the render.
  it "wraps the page in the frame the reorder response targets" do
    expect(rendered_component).to have_css("#statuses-index-component")
  end

  it "offers the filters above the table", :aggregate_failures do
    expect(rendered_component).to have_test_selector("add-status-button")
    expect(rendered_component).to have_css("#statuses-index-component #statuses-table .Box-row", text: "New")
  end
end
