# frozen_string_literal: true

module API
  module V3
    module MeetingAgendaItems
      class VotesAPI < ::API::OpenProjectAPI
        helpers do
          def vote_on_agenda_item(reaction)
            result = ::MeetingAgendaItems::VoteService
              .new(user: current_user, meeting_agenda_item: @meeting_agenda_item)
              .call(reaction:)

            raise_vote_error(result.errors) unless result.success?

            status :ok
            MeetingAgendaItemRepresenter.new(result.result, current_user:)
          end

          def raise_vote_error(errors)
            if errors.of_kind?(:base, :vote_based_sorting_required)
              raise ::API::Errors::BadRequest.new(errors.full_messages.join(" "))
            end

            raise ::API::Errors::ErrorBase.create_and_merge_errors(errors)
          end
        end

        post :upvote do
          vote_on_agenda_item("thumbs_up")
        end

        post :downvote do
          vote_on_agenda_item("thumbs_down")
        end
      end
    end
  end
end
