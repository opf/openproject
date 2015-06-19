#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory(:timeline, class: Timeline) do

    options(
      'exist'                     => '',
      'timeframe_start'           => '',
      'zoom_factor'               => ['1'],
      'timeframe_end'             => '',
      'initial_outline_expansion' => ['2']
    )

    association :project
    sequence(:name) { |n| "Timeline No. #{n}" }

  end
end

FactoryGirl.define do
  factory(:timeline_with_history, parent: :timeline) do

    sequence(:name) { |n| "Timeline No. #{n} with History" }

    callback(:after_create) do |timeline|

      # remove rails' automagic:

      # get all planning elements in this project

      timeline.project.planning_elements.each do |pe|

        10.times do
          print '.'; $stdout.flush

          delay = ([-1, 1].sample * rand(30)).days

          # delay all planning elements by a few days.

          pe.start_date = pe.start_date + delay
          pe.due_date = pe.due_date + delay
          pe.save

          # predate all journals by one week.

          predate = Proc.new do |e|
            fake = e.created_at - 1.week
            e.created_at = fake
            e.updated_at = fake
            e.save
            fake
          end

          PlanningElement.record_timestamps = false
          Journal.record_timestamps = false

          dates = pe.journals.map &predate

          Journal.record_timestamps = true

          earliest_update = dates.min
          latest_update = dates.max

          pe.updated_at = latest_update + 1.seconds
          pe.created_at = earliest_update - 1.week
          pe.save

          PlanningElement.record_timestamps = true
        end
      end

    end
  end
end
