class Meeting < ActiveRecord::Base
  belongs_to :project

  acts_as_journalized :event_title => Proc.new {|o| "#{o.scheduled_on} Meeting"},
                :event_datetime => :scheduled_on,
                :event_author => nil,
                :event_url => Proc.new {|o| {:controller => 'meetings', :action => 'show', :id => o.id}}
                :activity_timestamp => 'scheduled_on'
end
