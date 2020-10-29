# coding: utf-8

class PDF::Reader
  # remove duplicates from a collection of TextRun objects. This can be helpful when a PDF
  # uses slightly offset overlapping characters to achieve a fake 'bold' effect.
  class OverlappingRunsFilter

    # This should be between 0 and 1. If TextRun B obscures this much of TextRun A (and they
    # have identical characters) then one will be discarded
    OVERLAPPING_THRESHOLD = 0.5

    def self.exclude_redundant_runs(runs)
      sweep_line_status = Array.new
      event_point_schedule = Array.new
      to_exclude = []

      runs.each do |run|
        event_point_schedule << EventPoint.new(run.x, run)
        event_point_schedule << EventPoint.new(run.endx, run)
      end

      event_point_schedule.sort! { |a,b| a.x <=> b.x }

      event_point_schedule.each do |event_point|
        run = event_point.run

        if event_point.start?
          if detect_intersection(sweep_line_status, event_point)
            to_exclude << run
          end
          sweep_line_status.push(run)
        else
          sweep_line_status.delete(run)
        end
      end
      runs - to_exclude
    end

    def self.detect_intersection(sweep_line_status, event_point)
      sweep_line_status.each do |open_text_run|
        if event_point.x >= open_text_run.x &&
            event_point.x <= open_text_run.endx &&
            open_text_run.intersection_area_percent(event_point.run) >= OVERLAPPING_THRESHOLD
          return true
        end
      end
      return false
    end
  end

  # Utility class used to avoid modifying the underlying TextRun objects while we're
  # looking for duplicates
  class EventPoint
    attr_reader :x, :run

    def initialize x, run
      @x, @run = x, run
    end

    def start?
      @x == @run.x
    end
  end

end
