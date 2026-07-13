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

class CostQuery::Filter::WorkPackageId < Report::Filter::Base
  db_field "entries.entity_id"

  def self.label
    WorkPackage.model_name.human
  end

  def self.available_operators
    ["=", "!", "=_child_work_packages", "!_child_work_packages"].map(&:to_operator)
  end

  def self.available_values(*)
    []
  end

  ##
  # Overwrites Report::Filter::Base self.label_for_value method
  # to achieve a more performant implementation
  def self.label_for_value(value)
    return nil unless WorkPackage::SemanticIdentifier.numeric_id?(value.to_s)

    work_package = WorkPackage.visible.find(value.to_i)
    [text_for_work_package(work_package), work_package.id] if work_package&.visible?(User.current)
  end

  def self.text_for_tuple(id, subject)
    str = "##{id} "
    str << (subject.length > 30 ? "#{subject.first(26)}..." : subject)
  end

  def self.text_for_work_package(work_package_or_work_package_list)
    wp = if work_package_or_work_package_list.is_a?(Array)
           work_package_or_work_package_list.first
         else
           work_package_or_work_package_list
         end

    text_for_tuple(wp.id, wp.subject)
  end

  def sql_statement
    super.tap do |query|
      query.where << "entries.entity_type = 'WorkPackage'"
    end
  end
end
