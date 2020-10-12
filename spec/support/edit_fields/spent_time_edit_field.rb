require_relative './edit_field'

class SpentTimeEditField < EditField
  def time_log_icon_visible(visible)
    if visible
      expect(page).to have_selector("#{@selector} #{display_selector} #{icon}")
    else
      expect(page).to have_no_selector("#{@selector} #{display_selector} #{icon}")
    end
  end

  def open_time_log_modal
    page.find("#{@selector} #{display_selector} #{icon}").click
  end

  private

  def icon
    '.icon-time'
  end
end
