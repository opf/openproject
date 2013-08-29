#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory(:timeline, :class => Timeline) do

    options({
      'exist'                     => "",
      'timeframe_start'           => "",
      'zoom_factor'               => ["1"],
      'timeframe_end'             => "",
      'initial_outline_expansion' => ["2"]
    })

    association :project
    sequence(:name) { |n| "Timeline No. #{n}" }

  end
end

FactoryGirl.define do
  factory(:timeline_with_history, :parent => :timeline) do

    sequence(:name) { |n| "Timeline No. #{n} with History" }

    after_create do |timeline|

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
