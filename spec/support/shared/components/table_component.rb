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

RSpec.shared_examples_for "rendering generic table" do |expected_headers_count: nil, expected_rows_count: nil|
  with = []
  with << "#{expected_headers_count} headers" if expected_headers_count
  with << "#{expected_rows_count} rows" if expected_rows_count
  with = with.any? ? " with #{with.to_sentence}" : ""

  it "renders generic table#{with}" do
    expect(rendered_component).to have_selector :table
    if expected_headers_count
      expect(rendered_component).to have_css("colgroup > col", count: expected_headers_count)
                               .and have_css("thead th", count: expected_headers_count)
    end
    if expected_rows_count
      expect(rendered_component).to have_css "tbody tr", count: expected_rows_count
    end
  end
end
