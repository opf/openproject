class MeetingContent < ActiveRecord::Base
  unloadable
  
  acts_as_versioned
  
  belongs_to :meeting
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  
  class Version
    belongs_to :author, :class_name => '::User', :foreign_key => 'author_id'
  end
end