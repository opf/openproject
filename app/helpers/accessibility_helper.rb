module AccessibilityHelper
  def you_are_here_info(condition = true)
    condition ?
      "<span class = 'hidden-for-sighted'>#{l(:description_current_position)}</span>".html_safe :
      ""
  end
end
