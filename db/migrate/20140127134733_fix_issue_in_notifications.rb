class FixIssueInNotifications < ActiveRecord::Migration
  def up
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("issue_added","work_package_added")}
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("issue_updated","work_package_updated")}
  end

  def down
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("work_package_added","issue_added")}
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("work_package_updated","issue_updated")}
  end
end
