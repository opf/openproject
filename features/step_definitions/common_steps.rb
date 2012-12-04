# "Then I should see 5 articles"
Then /^I should see (\d+) ([^\" ]+)(?: within "([^\"]*)")?$/ do |number, name, selector|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_css(".#{name.singularize}", :count => number.to_i)
    else
      assert page.has_css?(".#{name.singularize}", :count => number.to_i)
    end
  end
end

Then /^I should not see(?: (\d+))? ([^\" ]+)(?: within "([^\"]*)")?$/ do |number, name, selector|
  options = number ? {:count => number.to_i} : {}
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_no_css(".#{name.singularize}", options)
    else
      assert page.has_no_css?(".#{name.singularize}", options)
    end
  end
end

Around('@changes_environment') do |scenario, block|
  saved_env = ENV["RAILS_ENV"]
  block.call
  ENV["RAILS_ENV"] = saved_env
end


Then /^I am in "([^\"]*)" mode$/ do |env|
  ENV["RAILS_ENV"] = env
end

Given /^the [pP]roject(?: "([^\"]+?)")? uses the following trackers:$/ do |project, table|
  project = get_project(project)

  trackers = table.raw.map do |line|
    name = line.first
    tracker = Tracker.find_by_name(name)

    tracker = FactoryGirl.create(:tracker, :name => name) if tracker.blank?
    tracker
  end

  project.update_attributes :tracker_ids => trackers.map(&:id).map(&:to_s)
end
