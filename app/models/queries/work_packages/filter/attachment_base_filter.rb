#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Queries::WorkPackages::Filter::AttachmentBaseFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::FilterOnTsvMixin
  include Queries::WorkPackages::Filter::TextFilterOnJoinMixin

  attr_reader :join_table_suffix

  def initialize(name, options = {})
    super name, options

    # Generate a uniq suffix to add to the join table
    # because attachment filters may be used multiple times
    @join_table_suffix = SecureRandom.hex(4)
  end

  def type
    :text
  end

  def available?
    EnterpriseToken.allows_to?(:attachment_filters) && OpenProject::Database.allows_tsv?
  end

  def where
    Queries::Operators::All.sql_for_field(values, join_table_alias, 'id')
  end

  protected

  def join_table_alias
    "#{self.class.key}_#{join_table}_#{join_table_suffix}"
  end

  def join_table
    Attachment.table_name
  end

  def join_condition
    <<-SQL
      #{join_table_alias}.container_id = #{WorkPackage.table_name}.id
      AND #{join_table_alias}.container_type = '#{WorkPackage.name}'
      AND #{tsv_condition}
    SQL
  end

  def tsv_condition
    OpenProject::FullTextSearch.tsv_where(join_table_alias,
                                          search_column,
                                          values.first,
                                          concatenation: concatenation,
                                          normalization: normalization_type)
  end

  def search_column
    raise NotImplementedError
  end

  def normalization_type
    :text
  end
end
