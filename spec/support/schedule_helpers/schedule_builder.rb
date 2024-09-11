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

module ScheduleHelpers
  class ScheduleBuilder
    def self.from_chart(chart)
      creator = new(chart)
      chart.work_package_names.each do |name|
        creator.create_work_package(name)
        creator.create_follows_relations(name)
      end
      Schedule.new(creator.work_packages, creator.follows_relations)
    end

    attr_reader :chart, :work_packages, :follows_relations

    def initialize(chart)
      @chart = chart
      @work_packages = {}
      @follows_relations = {}
    end

    def create_work_package(name)
      work_packages[name] ||= begin
        attributes = chart
          .work_package_attributes(name)
          .excluding(:name)
          .merge(parent: parent_of(name))
        FactoryBot.create(:work_package, attributes)
      end
    end

    def create_follows_relations(follower)
      chart.predecessors_by_follower(follower).each do |predecessor|
        follows_relations[from: follower, to: predecessor] =
          FactoryBot.create(:follows_relation,
                            from: create_work_package(follower),
                            to: create_work_package(predecessor),
                            lag: chart.lag_between(predecessor:, follower:))
      end
    end

    def parent_of(name)
      if chart.parent(name)
        create_work_package(chart.parent(name))
      end
    end
  end
end
