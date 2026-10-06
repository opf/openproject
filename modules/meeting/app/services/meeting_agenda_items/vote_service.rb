# frozen_string_literal: true

module MeetingAgendaItems
  class VoteService < ::BaseServices::BaseContracted
    def initialize(user:, meeting_agenda_item:, contract_class: nil, contract_options: {})
      super(user:, contract_class:, contract_options:)
      self.model = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
    end

    protected

    def service_context(send_notifications:, &)
      super do
        @meeting.with_lock do
          model.with_lock(&)
        end
      end
    end

    def before_perform(call)
      @reaction = params[:reaction].to_s
      self.contract_options = contract_options.merge(reaction: @reaction, meeting_id: @meeting.id)
      call
    end

    def persist(call)
      model.transaction(requires_new: true) { toggle_vote }
      call
    rescue ActiveRecord::RecordInvalid
      call.success = false
      call.errors = @vote.errors
      call
    end

    def default_contract_class
      MeetingAgendaItems::VoteContract
    end

    private

    def toggle_vote
      existing_vote = model.emoji_reactions.find_by(user:)
      previous_reaction = existing_vote&.reaction
      existing_vote&.destroy!

      if previous_reaction != @reaction
        @vote = model.emoji_reactions.build(user:, reaction: @reaction)
        @vote.save!
      end
    end
  end
end
