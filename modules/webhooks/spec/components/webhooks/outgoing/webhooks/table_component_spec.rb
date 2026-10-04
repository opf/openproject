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

RSpec.describe Webhooks::Outgoing::Webhooks::TableComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(rows: webhooks)
  end

  context "with no webhooks" do
    let(:webhooks) { create_list(:webhook, 0) }

    it_behaves_like "rendering generic table", expected_headers_count: 6, expected_rows_count: 1

    it "renders 'no webhooks' message" do
      expect(rendered_component).to have_selector(:row, text: "No webhooks have been defined yet.")
    end
  end

  context "with webhooks" do
    let(:webhooks) { create_list(:webhook, 2) }

    it_behaves_like "rendering generic table", expected_headers_count: 6, expected_rows_count: 2
  end
end
