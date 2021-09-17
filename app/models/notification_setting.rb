class NotificationSetting < ApplicationRecord
  WATCHED = :watched
  ASSIGNED = :assigned
  RESPONSIBLE = :responsible
  MENTIONED = :mentioned
  WORK_PACKAGE_CREATED = :work_package_created
  WORK_PACKAGE_COMMENTED = :work_package_commented
  WORK_PACKAGE_PROCESSED = :work_package_processed
  WORK_PACKAGE_PRIORITIZED = :work_package_prioritized
  WORK_PACKAGE_SCHEDULED = :work_package_scheduled
  NEWS_ADDED = :news_added
  NEWS_COMMENTED = :news_commented
  DOCUMENT_ADDED = :document_added
  FORUM_MESSAGES = :forum_messages
  WIKI_PAGE_ADDED = :wiki_page_added
  WIKI_PAGE_UPDATED = :wiki_page_updated
  MEMBERSHIP_ADDED = :membership_added
  MEMBERSHIP_UPDATED = :membership_updated
  ALL = :all

  def self.all_settings
    [
      WATCHED,
      ASSIGNED,
      RESPONSIBLE,
      MENTIONED,
      WORK_PACKAGE_CREATED,
      WORK_PACKAGE_COMMENTED,
      WORK_PACKAGE_PROCESSED,
      WORK_PACKAGE_PRIORITIZED,
      WORK_PACKAGE_SCHEDULED,
      NEWS_ADDED,
      NEWS_COMMENTED,
      DOCUMENT_ADDED,
      FORUM_MESSAGES,
      WIKI_PAGE_ADDED,
      WIKI_PAGE_UPDATED,
      MEMBERSHIP_ADDED,
      MEMBERSHIP_UPDATED,
      ALL
    ]
  end

  enum channel: { in_app: 0, mail: 1, mail_digest: 2 }

  belongs_to :project
  belongs_to :user

  include Scopes::Scoped
  scopes :applicable

  validates :channel, uniqueness: { scope: %i[project user] }
end
