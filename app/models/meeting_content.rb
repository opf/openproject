class MeetingContent < ActiveRecord::Base
  unloadable

  belongs_to :meeting
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  attr_accessor :comment

  validates_length_of :comment, :maximum => 255, :allow_nil => true

  before_save :comment_to_journal_notes

  def editable?
    true
  end

  def diff(version_to=nil, version_from=nil)
    version_to = version_to ? version_to.to_i : self.version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to

    content_to = self.journals.find_by_version(version_to)
    content_from = self.journals.find_by_version(version_from)

    (content_to && content_from) ? WikiDiff.new(content_to, content_from) : nil
  end

  # Compatibility for mailer.rb
  def updated_on
    updated_at
  end

  # Show the project on activity and search views
  def project
    meeting.project
  end

  # Provided for compatibility of the old pre-journalized migration
  def self.create_versioned_table
  end

  # Provided for compatibility of the old pre-journalized migration
  def self.drop_versioned_table
  end

  private

  def comment_to_journal_notes
    init_journal(author, comment) unless changes.empty?
  end
end