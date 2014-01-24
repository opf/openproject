
module PdfExportNavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /^the taskboard card configurations index page$/
      "/taskboard_card_configurations"

    else
      super
    end
  end
end

World(PdfExportNavigationHelpers)