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

RSpec.shared_examples_for "rendering Border Box Grid heading" do |text:|
  it "renders Border Box Grid heading '#{text}'" do
    expect(rendered_component).to have_css ".op-border-box-grid__header", text:
  end
end

RSpec.shared_examples_for "rendering Border Box Grid mobile heading" do |text:|
  it "renders Border Box Grid mobile heading '#{text}'" do
    expect(rendered_component).to have_css ".op-border-box-grid__mobile-header", text:
  end
end

RSpec.shared_examples_for "rendering Border Box Grid rows" do |row_count:, col_count:|
  it "renders rows", :aggregate_failures do
    expect(rendered_component).to have_css ".Box-row", count: row_count
    expect(rendered_component).to have_css ".Box-row" do |row|
      expect(row).to have_css ".op-border-box-grid__row-item", count: col_count
    end
  end
end
