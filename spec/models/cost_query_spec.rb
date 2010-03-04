require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostEntry do

  before(:each) do
    User.current = users("admin")
  end

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :enumerations
  fixtures :enabled_modules
  fixtures :issue_statuses

end