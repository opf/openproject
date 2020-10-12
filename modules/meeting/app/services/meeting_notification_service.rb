class MeetingNotificationService

  attr_reader :meeting, :content_type

  def initialize(meeting, content_type)
    @meeting = meeting
    @content_type = content_type
  end

  def call(content, action, include_author: false)
    recipients_with_errors = send_notifications!(content, action, include_author: include_author)
    ServiceResult.new(success: recipients_with_errors.empty?, errors: recipients_with_errors)
  end

  private

  def send_notifications!(content, action, include_author:)
    author_mail = meeting.author.mail
    do_not_notify_author = meeting.author.pref[:no_self_notified] && !include_author

    recipients_with_errors = []
    meeting.participants.includes(:user).each do |recipient|
      begin
        next if recipient.mail == author_mail && do_not_notify_author

        MeetingMailer.send(action, content, content_type, recipient.user).deliver_now
      rescue => e
        Rails.logger.error {
          "Failed to deliver #{action} notification to #{recipient.mail}: #{e.message}"
        }
        recipients_with_errors << recipient
      end
    end

    recipients_with_errors
  end
end
