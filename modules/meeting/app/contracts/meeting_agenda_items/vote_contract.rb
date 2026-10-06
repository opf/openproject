# frozen_string_literal: true

module MeetingAgendaItems
  class VoteContract < ::ModelContract
    validate :validate_voting_permission
    validate :validate_sorting_mode, if: -> { errors.empty? }
    validate :validate_voting_available, if: -> { errors.empty? }
    validate :validate_reaction, if: -> { errors.empty? }

    protected

    def validate_model?
      false
    end

    private

    def validate_voting_permission
      if (options[:meeting_id] && model.meeting_id != options[:meeting_id]) ||
         !user.allowed_in_project?(:view_meetings, model.meeting.project)
        errors.add :base, :error_unauthorized
      end
    end

    def validate_sorting_mode
      errors.add :base, :vote_based_sorting_required unless model.meeting.agenda_sorting_vote_based?
    end

    def validate_voting_available
      errors.add :base, :error_unauthorized unless model.votable?(user)
    end

    def validate_reaction
      unless MeetingAgendaItem.allowed_emoji_reactions.include?(options[:reaction].to_s)
        errors.add :base, I18n.t("meeting.agenda_sorting.invalid_reaction")
      end
    end
  end
end
