# frozen_string_literal: true

module Meetings
  class AgendaSortingDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(meeting:)
      super()
      @meeting = meeting
    end

    def render?
      @meeting.editable?
    end
  end
end
