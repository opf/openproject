# frozen_string_literal: true

# -- copyright
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
# ++

class Queries::Serialization::GroupBys
  include Queries::GroupBys::AvailableGroupBys

  def load(serialized_group_bys)
    return [] if serialized_group_bys.nil?

    serialized_group_bys.map do |group_by|
      group_by_for(group_by.to_sym)
    end
  end

  def dump(group_bys)
    group_bys.map { |group_by| group_by.attribute.to_s }
  end

  def group_by_register
    ::Queries::Register.group_bys[klass]
  end

  def initialize(klass)
    @klass = klass
  end

  attr_reader :klass
end
