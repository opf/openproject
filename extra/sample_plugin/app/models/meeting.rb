class Meeting < ActiveRecord::Base
  belongs_to :project
  
  acts_as_activity_provider :timestamp => 'scheduled_on',
                            :find_options => { :include => :project }
end
