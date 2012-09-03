module Notifier
  def self.notify?(event)
    notified_events.include?(event.to_s)
  end
  
  def self.notified_events
    Setting.notified_events.to_a
  end
end
