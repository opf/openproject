# frozen_string_literal: true

module MeetingAgendaItems
  class VoteControlsComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting_agenda_item:, voting_enabled:)
      super()

      @meeting_agenda_item = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
      @voting_enabled = voting_enabled
    end

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    private

    def vote_selected?(reaction)
      @current_vote = @meeting_agenda_item.vote_by(User.current) unless defined?(@current_vote)
      @current_vote == reaction
    end

    def vote_label(reaction)
      label_key = vote_selected?(reaction) ? "remove_#{reaction}" : reaction
      t("meeting.agenda_sorting.#{label_key}")
    end

    def vote_icon(reaction)
      reaction == "thumbs_up" ? "👍" : "👎"
    end
  end
end
