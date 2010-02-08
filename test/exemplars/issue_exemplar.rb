class Issue < ActiveRecord::Base
  generator_for :subject, :method => :next_subject
  generator_for :author, :method => :next_author
  generator_for :priority, :method => :fetch_priority
  
  def self.next_subject
    @last_subject ||= 'Subject 0'
    @last_subject.succ!
    @last_subject
  end

  def self.next_author
    User.generate_with_protected!
  end

  def self.fetch_priority
    IssuePriority.first || IssuePriority.generate!
  end

end
