# frozen_string_literal: true

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

module Queries::WorkPackages::StoredNames
  def self.stored_select(name) = Queries::WorkPackages::Selects::PropertySelect.stored_name(name)

  def self.offered_select(name) = Queries::WorkPackages::Selects::PropertySelect.offered_name(name)

  def self.stored_filter(key)
    return nil if key.nil?

    Query.find_registered_filter(key)&.stored_key&.to_s || key
  end

  def self.offered_filter(stored)
    return nil if stored.nil?

    declaration = alias_declaration_for(stored)
    return stored unless declaration

    offered = available_alias_of(declaration)
    return stored if offered.nil? || offered.key.to_s == stored.to_s

    offered.key.to_s
  end

  def self.alias_declaration_for(stored)
    Query.registered_filters.find do |filter|
      filter.stored_key && [filter.key, filter.stored_key].map(&:to_s).include?(stored.to_s)
    end
  end
  private_class_method :alias_declaration_for

  def self.available_alias_of(declaration)
    candidates = [Query.find_registered_filter(declaration.stored_key), declaration].compact
    candidates.find { it.create!(name: it.key).available? }
  end
  private_class_method :available_alias_of
end
