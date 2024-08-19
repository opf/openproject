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

class Queries::Projects::Filters::NameFilter < Queries::Projects::Filters::Base
  def type
    :string
  end

  def where
    case operator
    when "="
      ["LOWER(projects.name) IN (?)", sql_value]
    when "!"
      ["LOWER(projects.name) NOT IN (?)", sql_value]
    when "~", "**"
      ["LOWER(projects.name) LIKE ?", "%#{sql_value}%"]
    when "!~"
      ["LOWER(projects.name) NOT LIKE ?", "%#{sql_value}%"]
    end
  end

  def human_name
    I18n.t(:label_name)
  end

  def self.key
    :name
  end

  private

  def sql_value
    case operator
    when "=", "!"
      values.map { |val| self.class.connection.quote_string(val.downcase) }.join(",")
    when "**", "~", "!~"
      values.first.downcase
    end
  end
end
