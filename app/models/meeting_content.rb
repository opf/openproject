class MeetingContent < ActiveRecord::Base
  acts_as_versioned
  
  belongs_to :meeting
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
end
