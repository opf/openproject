FactoryGirl.define do
  factory(:timelines_timeline, :class => Timelines::Timeline) do

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
  factory(:timelines_timeline_with_history, :parent => :timelines_timeline) do

    sequence(:name) { |n| "Timeline No. #{n} with History" }

    after_create do |timeline|

      # remove rails' automagic:

      # get all planning elements in this project

      timeline.project.timelines_planning_elements.each do |pe|

        10.times do
          print '.'; $stdout.flush

          delay = ([-1, 1].sample * rand(30)).days

          # delay all planning elements by a few days.

          pe.start_date = pe.start_date + delay
          pe.end_date = pe.end_date + delay
          pe.save

          # predate all journals and alternate dates by one week.

          predate = Proc.new do |e|
            fake = e.created_at - 1.week
            e.created_at = fake
            e.updated_at = fake
            e.save
            fake
          end

          Timelines::PlanningElement.record_timestamps = false
          Timelines::AlternateDate.record_timestamps = false
          Journal.record_timestamps = false

          dates = pe.journals.map &predate
          pe.alternate_dates.each &predate

          Timelines::AlternateDate.record_timestamps = true
          Journal.record_timestamps = true

          earliest_update = dates.min
          latest_update = dates.max

          pe.updated_at = latest_update + 1.seconds
          pe.created_at = earliest_update - 1.week
          pe.save

          Timelines::PlanningElement.record_timestamps = true
        end
      end

    end
  end
end
