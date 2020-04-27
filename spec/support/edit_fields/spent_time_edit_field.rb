require_relative './edit_field'

class SpentTimeEditField < EditField
  def timeLogIconVisible(visible)
    if visible
      expect(page).to have_selector("#{@selector} #{display_selector} #{icon}")
    else
      expect(page).to have_no_selector("#{@selector} #{display_selector} #{icon}")
    end
  end

  def openTimeLogModal
    page.find("#{@selector} #{display_selector} #{icon}").click
  end

  private

  def icon
    '.icon-time'
  end
end
