# Patch the data from a boolean change.
class UpdateMailNotificationValues < ActiveRecord::Migration
  def self.up
    User.record_timestamps = false
    User.all.each do |u|
      u.mail_notification = if u.mail_notification =~ /\A(1|t)\z/
                              # User set for all email (t is for sqlite)
                              'all'
                            else
                              # User wants to recieve notifications on specific projects?
                              if u.memberships.count(:conditions => {:mail_notification => true}) > 0
                                'selected'
                              else
                                'only_my_events'
                              end
                            end
      u.save!
    end
    User.record_timestamps = true
  end

  def self.down
    # No-op
  end
end
