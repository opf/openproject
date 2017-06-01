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

class ParseSchemaFilterParamsService
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call(filter)
    error_message = check_error_in_filter(filter)

    if error_message
      error(error_message)
    else
      pairs = valid_project_type_pairs(filter)

      success(pairs)
    end
  end

  private

  def check_error_in_filter(filter)
    if !filter.first['id']
      :id_filter_required
    elsif filter.first['id']['operator'] != '='
      :unsupported_operator
    elsif filter.first['id']['values'].any? { |id_string| !id_string.match(/\d+-\d+/) }
      :invalid_values
    end
  end

  def parse_ids(filter)
    ids_string = filter.first['id']['values']

    ids_string.map do |id_string|
      id_string.split('-')
    end
  end

  def error(message)
    errors = ActiveModel::Errors.new(self)
    errors.add(:base, message)
    ServiceResult.new(errors: errors)
  end

  def success(result)
    ServiceResult.new(success: true, result: result)
  end

  def valid_project_type_pairs(filter)
    ids = parse_ids(filter)

    projects_map = projects_by_id(ids.map(&:first))
    types_map = types_by_id(ids.map(&:last))

    valid_ids = only_valid_pairs(ids, projects_map, types_map)

    string_pairs_to_object_pairs(valid_ids, projects_map, types_map)
  end

  def projects_by_id(ids)
    Project.visible(user).where(id: ids).group_by(&:id)
  end

  def types_by_id(ids)
    Type.where(id: ids).group_by(&:id)
  end

  def only_valid_pairs(id_pairs, projects_map, types_map)
    id_pairs.reject do |project_id, type_id|
      projects_map[project_id.to_i].nil? || types_map[type_id.to_i].nil?
    end
  end

  def string_pairs_to_object_pairs(string_pairs, projects_map, types_map)
    string_pairs.map do |project_id, type_id|
      [projects_map[project_id.to_i].first, types_map[type_id.to_i].first]
    end
  end
end
