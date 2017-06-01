#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal::BaseJournal < ActiveRecord::Base
  self.abstract_class = true

  belongs_to :journal

  def journaled_attributes
    attributes.symbolize_keys.select { |k, _| self.class.journaled_attributes.include? k }
  end

  def self.journaled_attributes
    @journaled_attributes ||= column_names.map(&:to_sym) - excluded_attributes
  end

  private

  def self.column_names
    db_columns(table_name).map(&:name)
  end

  def self.excluded_attributes
    [primary_key.to_sym, inheritance_column.to_sym, :journal_id, :lock_version, :created_at, :root_id, :lft, :rgt]
  end

  def self.db_columns(table_name)
    ActiveRecord::Base.connection.columns table_name
  end
end
