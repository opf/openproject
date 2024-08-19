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

Dir[Rails.root.join("spec/support/table_helpers/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.extend TableHelpers::LetWorkPackages
  config.include TableHelpers::ExampleMethods

  RSpec::Matchers.define :match_table do |expected|
    match do |actual_work_packages|
      expected_data = TableHelpers::TableData.for(expected)
      actual_data = TableHelpers::TableData.from_work_packages(actual_work_packages, expected_data.columns)
      actual_data.order_like!(expected_data)

      representer = TableHelpers::TableRepresenter.new(tables_data: [expected_data, actual_data],
                                                       columns: expected_data.columns)
      @expected = representer.render(expected_data)
      @actual = representer.render(actual_data)

      values_match? @expected, @actual
    end

    diffable
    attr_reader :expected, :actual
  end
end
