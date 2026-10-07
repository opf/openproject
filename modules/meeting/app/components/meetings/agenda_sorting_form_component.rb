# frozen_string_literal: true

module Meetings
  class AgendaSortingFormComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super()
      @meeting = meeting
    end
  end
end
