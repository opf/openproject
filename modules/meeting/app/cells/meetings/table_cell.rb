module Meetings
  class TableCell < ::TableCell
    options :current_project # used to determine if displaying the projects column

    sortable_columns :title, :start_time, :duration, :location

    def initial_sort
      %i[start_time asc]
    end

    def paginated?
      true
    end

    def headers
      @headers ||= [
        [:title, { caption: Meeting.human_attribute_name(:title) }],
        current_project.blank? ? [:project, { caption: Meeting.human_attribute_name(:project) }] : nil,
        [:start_time, { caption: Meeting.human_attribute_name(:start_time) }],
        [:duration, { caption: Meeting.human_attribute_name(:duration) }],
        [:location, { caption: Meeting.human_attribute_name(:location) }]
      ].compact
    end

    def columns
      @columns ||= headers.map(&:first)
    end
  end
end
