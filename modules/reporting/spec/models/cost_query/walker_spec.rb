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

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

RSpec.describe CostQuery, :reporting_query_helper do
  minimal_query

  before do
    create(:admin)
    project = create(:project_with_types)
    work_package = create(:work_package, project:)
    create(:time_entry, work_package:, project:)
  end

  describe Report::Transformer do
    it "walks down row_first" do
      query.group_by :work_package_id
      query.column :tweek
      query.row :project_id
      query.row :user_id

      result = query.transformer.row_first.values.first
      %i[user_id project_id tweek].each do |field|
        expect(result.fields).to include(field)
        result = result.values.first
      end
    end

    it "walks down column_first" do
      query.group_by :work_package_id
      query.column :tweek
      query.row :project_id
      query.row :user_id

      result = query.transformer.column_first.values.first
      %i[tweek work_package_id].each do |field|
        expect(result.fields).to include(field)
        result = result.values.first
      end
    end
  end
end
