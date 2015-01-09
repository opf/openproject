#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class CostQuery::Filter::WorkPackageId < Report::Filter::Base
  def self.label
    WorkPackage.model_name.human
  end

  def self.available_values(*)
    work_packages = Project.visible.map { |p| p.work_packages }.flatten.uniq.sort_by { |i| i.id }
    work_packages.map { |i| [text_for_work_package(i), i.id] }
  end

  def self.heavy?
    true
  end
  not_selectable! if heavy?

  ##
  # Overwrites Report::Filter::Base self.label_for_value method
  # to achieve a more performant implementation
  def self.label_for_value(value)
    return nil unless value.to_i.to_s == value.to_s # we expect an work_package-id
    work_package = WorkPackage.find(value.to_i)
    [text_for_work_package(work_package), work_package.id] if work_package and work_package.visible?(User.current)
  end

  def self.text_for_work_package(i)
    i = i.first if i.is_a? Array
    str = "##{i.id} "
    str << (i.subject.length > 30 ? i.subject.first(26) + '...' : i.subject)
  end

  def self.text_for_id(i)
    text_for_work_package WorkPackage.find(i)
  rescue ActiveRecord::RecordNotFound
    ''
  end
end
