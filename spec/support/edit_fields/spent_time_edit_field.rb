# frozen_string_literal: true

require_relative "edit_field"

class SpentTimeEditField < EditField
  def time_log_icon_visible(visible)
    if visible
      expect(page).to have_css("#{@selector} #{display_selector} #{icon}")
    else
      expect(page).to have_no_css("#{@selector} #{display_selector} #{icon}")
    end
  end

  def open_time_log_modal
    wait_for_network_idle(duration: 0.3)
    page.find("#{@selector} #{display_selector} #{icon}").click
    page.find("dialog#time-entry-dialog", visible: :all, wait: 30)
  end

  private

  def icon
    ".icon-time"
  end
end
