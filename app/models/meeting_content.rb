class MeetingContent < ActiveRecord::Base
  unloadable
  
  acts_as_versioned
  
  belongs_to :meeting
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  
  def editable?
    true
  end
  
  def diff(version_to=nil, version_from=nil)
    version_to = version_to ? version_to.to_i : self.version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to
    
    content_to = self.find_version(version_to)
    content_from = self.find_version(version_from)
    
    (content_to && content_from) ? WikiDiff.new(content_to, content_from) : nil
  end
  
  # Compatibility for mailer.rb
  def updated_on
    updated_at
  end
  
  # The above breaks acts_as_versioned in some cases, this works around it
  self.non_versioned_columns << 'updated_on'
  
  protected
  
  def after_initialize
    self.comment = nil unless self.new_record? # Don't reset the comment if we haven't been saved with it yet
  end
  
  class Version
    unloadable
    
    belongs_to :author, :class_name => '::User', :foreign_key => 'author_id'
    belongs_to :meeting, :class_name => '::Meeting', :foreign_key => 'meeting_id'
    
    def editable?
      false
    end
  end
end