class Meeting < ActiveRecord::Base
  belongs_to :project

  acts_as_event :title => Proc.new {|o| "#{o.scheduled_on} Meeting"},
                :datetime => :scheduled_on,
                :author => nil,
                :url => Proc.new {|o| {:controller => 'meetings', :action => 'show', :id => o.id}}                
  
  acts_as_activity_provider :timestamp => 'scheduled_on',
                            :find_options => { :include => :project }
end
