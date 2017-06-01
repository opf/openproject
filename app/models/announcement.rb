class Announcement < ActiveRecord::Base
  scope :active,  -> { where(active: true) }
  scope :current, -> { where('show_until >= ?', Date.today) }

  validates :show_until, presence: true

  def self.active_and_current
    active.current.first
  end

  def self.only_one
    a = first
    a = create_default_announcement if a.nil?
    a
  end

  def active_and_current?
    active? && show_until && show_until >= Date.today
  end

  def self.create_default_announcement
    Announcement.create text: 'Announcement',
                        show_until: Date.today + 14.days,
                        active: false
  end
end
