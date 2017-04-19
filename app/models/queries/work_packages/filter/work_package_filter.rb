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

class Queries::WorkPackages::Filter::WorkPackageFilter < ::Queries::Filters::Base
  include ActiveModel::Serialization

  self.model = WorkPackage

  # (de-)serialization
  def self.from_hash(filter_hash)
    filter_hash.keys.map { |field| new(field, filter_hash[field]) }
  end

  def to_hash
    { name => attributes_hash }
  end

  def human_name
    WorkPackage.human_attribute_name(name)
  end

  def project
    context.project
  end

  def attributes
    { name: name, operator: operator, values: values }
  end

  def possible_types_by_operator
    self.class.operators_by_filter_type.select { |_key, operators| operators.include?(operator) }.keys.sort
  end

  def ==(filter)
    filter.attributes_hash == attributes_hash
  end

  protected

  def attributes_hash
    self.class.filter_params.inject({}) do |params, param_field|
      params.merge(param_field => send(param_field))
    end
  end

  private

  def stringify_values
    unless values.nil?
      values.map!(&:to_s)
    end
  end
end
