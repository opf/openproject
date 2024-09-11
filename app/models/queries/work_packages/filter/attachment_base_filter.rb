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

class Queries::WorkPackages::Filter::AttachmentBaseFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::TextFilterOnJoinMixin

  def type
    :text
  end

  def available?
    OpenProject::Database.allows_tsv?
  end

  protected

  def where_condition
    <<-SQL
      SELECT 1 FROM #{attachment_table}
      WHERE #{attachment_table}.container_id = #{WorkPackage.table_name}.id
      AND #{attachment_table}.container_type = '#{WorkPackage.name}'
      #{tsv_condition}
    SQL
  end

  def attachment_table
    Attachment.table_name
  end

  def tsv_condition
    condition = OpenProject::FullTextSearch.tsv_where(attachment_table,
                                                      search_column,
                                                      values.first,
                                                      normalization: normalization_type)

    if condition
      "AND #{condition}"
    else
      ""
    end
  end

  def search_column
    raise NotImplementedError
  end

  def normalization_type
    :text
  end
end
