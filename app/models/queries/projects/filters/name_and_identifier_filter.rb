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

class Queries::Projects::Filters::NameAndIdentifierFilter < Queries::Projects::Filters::ProjectFilter
  def type
    :string
  end

  def where
    case operator
    when '='
      where_equal(values)
    when '!'
      where_not(values)
    when '~'
      where_contains(values)
    when '!~'
      where_not_contains(values)
    end
  end

  def human_name
    I18n.t('query_fields.name_or_identifier')
  end

  def self.key
    :name_and_identifier
  end

  private

  def where_equal(values)
    conditions = []
    assignments = []
    values.each do |value|
      conditions << "LOWER(projects.identifier) = ? OR LOWER(projects.name) = ?"
      assignments = assignments + [value.downcase, value.downcase]
    end
    [conditions.join(' OR '), *assignments]
  end

  def where_not(values)
    conditions = []
    assignments = []
    values.each do |value|
      conditions << "LOWER(projects.identifier) <> ? AND LOWER(projects.name) <> ?"
      assignments = assignments + [value.downcase, value.downcase]
    end
    [conditions.join(' AND '), *assignments]
  end

  def where_contains(values)
    conditions = []
    assignments = []
    values.each do |value|
      conditions << "LOWER(projects.identifier) LIKE ? OR LOWER(projects.name) LIKE ?"
      assignments = assignments + ["%#{value.downcase}%", "%#{value.downcase}"]
    end
    [conditions.join(' OR '), *assignments]
  end

  def where_not_contains(values)
    conditions = []
    assignments = []
    values.each do |value|
      conditions << "LOWER(projects.identifier) LIKE ? OR LOWER(projects.name) LIKE ?"
      assignments = assignments + ["%#{value.downcase}%", "%#{value.downcase}"]
    end
    ["NOT(#{conditions.join(' OR ')})", *assignments]
  end

end
