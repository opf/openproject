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
    when /^the hourly rates page of user "(.*)" of the project called "(.*)"/
      user = User.find_by_login($1)
      "/projects/#{$2}/hourly_rates/#{user.id}"
    else
      super
    end
  end
end

World(CostNavigationHelpers)
