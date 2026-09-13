# frozen_string_literal: true

module Cde
  module Concerns
    module Stateful
      extend ActiveSupport::Concern

      included do
        include AASM
        enum status: { wip: 0, shared: 1, published: 2, archived: 3 }
      end

      aasm column: 'status', enums: true do
        state :wip, initial: true
        state :shared
        state :published
        state :archived

        event :share do
          transitions from: :wip, to: :shared,
                      before: -> { audit_transition('container.shared', current_user) }
        end

        event :return_to_wip do
          transitions from: :shared, to: :wip,
                      before: -> { audit_transition('container.returned_to_wip', current_user) }
        end

        event :publish do
          before do
            Cde::PublicationGate.enforce(self)
          end
          transitions from: :shared, to: :published,
                      before: -> { audit_transition('container.published', current_user) }
        end

        event :archive do
          transitions from: :published, to: :archived,
                      before: -> { audit_transition('container.archived', current_user) }
        end
      end

      private

      def current_user
        @current_user ||= User.current
      rescue StandardError
        nil
      end

      def audit_transition(action, user)
        Cde::AuditEvent.create!(
          auditable: self,
          user: user,
          action: action,
          event_type: 'state_transition',
          old_state: { status: transition_from },
          new_state: { status: transition_to },
          reason: 'State transition per ISO 19650 workflow'
        )
      end
    end
  end
end
