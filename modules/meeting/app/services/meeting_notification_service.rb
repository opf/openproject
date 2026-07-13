# frozen_string_literal: true

class MeetingNotificationService
  attr_reader :meeting, :content_type

  def initialize(meeting)
    @meeting = meeting
  end

  def call(action, **)
    if meeting.notify?
      recipients_with_errors = send_notifications!(action, **)
      ServiceResult.new(success: recipients_with_errors.empty?, errors: recipients_with_errors)
    else
      ServiceResult.failure(errors: meeting.participants.includes(:user))
    end
  end

  private

  def send_notifications!(action, **)
    recipients_with_errors = []
    meeting.participants.includes(:user).find_each do |recipient|
      send_notification(action, recipient, **)
    rescue StandardError => e
      Rails.logger.error do
        "Failed to deliver #{action} notification to #{recipient.mail}: #{e.message}"
      end
      recipients_with_errors << recipient
    end

    recipients_with_errors
  end

  def send_notification(action, recipient, **)
    notification_mail(action, recipient, **).deliver_later
  end

  ##
  # Sends the appropriate notification mail based on the action and recipient.
  # In some cases, we need to send a different mail for series and standalone occurrences
  # because the participant may be invited to the series or only the standalone occurrence.
  def notification_mail(action, recipient, **)
    if series_invite?(action)
      send_series_invite(recipient)
    else
      MeetingMailer.public_send(action, meeting, recipient.user, User.current, **)
    end
  end

  def send_series_invite(recipient)
    if template_participant_user_ids.include?(recipient.user_id)
      MeetingSeriesMailer.invited(meeting.recurring_meeting, recipient.user, User.current)
    else
      MeetingMailer.invited(meeting, recipient.user, User.current, standalone_occurrence: true)
    end
  end

  def series_invite?(action)
    action == :invited && meeting.recurring?
  end

  def template_participant_user_ids
    @template_participant_user_ids ||= MeetingParticipant.where(meeting_id: meeting.recurring_meeting.template.id).pluck(:user_id)
  end
end
