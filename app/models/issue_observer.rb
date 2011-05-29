class IssueObserver < ActiveRecord::Observer
  attr_accessor :send_notification
  
  def after_create(issue)
    if self.send_notification
      Mailer.deliver_issue_add(issue) if Setting.notified_events.include?('issue_added')
    end
    clear_notification
  end
  
  # Wrap send_notification so it defaults to true, when it's nil
  def send_notification
    return true if @send_notification.nil?
    return @send_notification
  end
  
  private

  # Need to clear the notification setting after each usage otherwise it might be cached
  def clear_notification
    @send_notification = true
  end
end
