module Meetings
  class RowCell < ::RowCell
    include ApplicationHelper

    def project
      link_to_project model.project, {}, {}, false
    end

    def title
      link_to model.title, meeting_path(model)
    end

    def start_time
      safe_join([format_date(model.start_time), format_time(model.start_time, false)], " ")
    end

    def duration
      "#{number_with_delimiter model.duration} h"
    end

    def location
      h(model.location)
    end
  end
end
