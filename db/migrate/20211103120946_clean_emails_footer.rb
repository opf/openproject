class CleanEmailsFooter < ActiveRecord::Migration[6.1]
  def up
    Setting.reset_column_information
    filtered_footer = Setting
      .emails_footer
      .reject do |locale, text|
      if assumed_notification_text?(text)
        warn "Removing emails footer for #{locale} as it matches the default notification syntax."
        true
      end
    end

    if filtered_footer.length < Setting.emails_footer.length
      Setting.emails_footer = filtered_footer
    end
  end

  def down
    # Nothing to migrate
  end

  private

  def assumed_notification_text?(text)
    [
      'You have received this notification because of your notification settings',
      'You have received this notification because you have either subscribed to it, or are involved in it.',
      'Sie erhalten diese E-Mail aufgrund Ihrer Benachrichtungseinstellungen',
      '/my/account',
      '/my/notifications',
      '/my/mail\_notifications'
    ].any? { |val| text.include?(val) }
  end
end
