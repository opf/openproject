class MeetingContent < ActiveRecord::Base
  unloadable
  
  acts_as_versioned
  
  belongs_to :meeting
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  
  def editable?
    true
  end
  
  class Version
    unloadable
    
    belongs_to :author, :class_name => '::User', :foreign_key => 'author_id'
    
    def editable?
      false
    end
  end
end