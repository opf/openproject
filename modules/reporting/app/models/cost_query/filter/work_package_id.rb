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
  def self.label
    WorkPackage.model_name.human
  end

  def self.available_values(*)
    WorkPackage
      .where(project_id: Project.allowed_to(User.current, :view_work_packages))
      .order(:id)
      .pluck(:id, :subject)
      .map { |id, subject| [text_for_tuple(id, subject), id] }
  end

  def self.available_operators
    ["="].map(&:to_operator)
  end

  ##
  # Overwrites Report::Filter::Base self.label_for_value method
  # to achieve a more performant implementation
  def self.label_for_value(value)
    return nil unless value.to_i.to_s == value.to_s # we expect an work_package-id

    work_package = WorkPackage.find(value.to_i)
    [text_for_work_package(work_package), work_package.id] if work_package and work_package.visible?(User.current)
  end

  def self.text_for_tuple(id, subject)
    str = "##{id} "
    str << (subject.length > 30 ? subject.first(26) + "..." : subject)
  end

  def self.text_for_work_package(i)
    i = i.first if i.is_a? Array
    text_for_touble(i.id, i.subject)
  end
end
