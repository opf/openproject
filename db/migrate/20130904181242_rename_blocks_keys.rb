#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

class RenameBlocksKeys < ActiveRecord::Migration[5.0]
  REPLACED = {
    "issuesassignedtome" => "work_packages_assigned_to_me",
    "issuesreportedbyme" => "work_packages_reported_by_me",
    "issuetracking" => "work_package_tracking",
    "issueswatched" => "work_packages_watched",
    "news" => "news_latest",
    "timelog" => "spent_time",
    "projectdetails" => "project_details",
    "projectdescription" => "project_description"
  }

  def self.up
    migrate(REPLACED)
  end

  def self.down
    migrate(REPLACED.invert)
  end

  def self.migrate(replacer)
    MyProjectsOverview.all.each do |my_project_overview|
      ['top', 'left', 'right', 'hidden'].each do |attribute|
        old = my_project_overview.send(attribute)
        my_project_overview.send(attribute+'=',replace(old,replacer))
      end
      my_project_overview.save!
    end
  end

  def self.replace(array, replacer)
    array.map { |element| replacer[element] ? replacer[element] : element }
  end
end
