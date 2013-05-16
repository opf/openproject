module CostNavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /^the show page (?:of|for) the budget "(.+)?"$/
      budget = CostObject.find_by_subject($1)
      "/cost_objects/#{budget.id}"
    when /^the index page (?:of|for) cost types$/
      "/cost_types"
    else
      super
    end
  end
end

World(CostNavigationHelpers)
