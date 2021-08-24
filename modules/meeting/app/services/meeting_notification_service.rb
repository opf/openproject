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

    recipients_with_errors = []
    meeting.participants.includes(:user).each do |recipient|
      next if recipient.mail == author_mail && !include_author

      MeetingMailer.send(action, content, content_type, recipient.user).deliver_now
    rescue StandardError => e
      Rails.logger.error do
        "Failed to deliver #{action} notification to #{recipient.mail}: #{e.message}"
      end
      recipients_with_errors << recipient
    end

    recipients_with_errors
  end
end
