module AnnouncementsHelper
  def notice_annoucement_active
    if @announcement.active_and_current?
      I18n.t(:'announcements.is_active')
    else
      I18n.t(:'announcements.is_inactive')
    end
  end
end
