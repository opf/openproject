#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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

Given /^the [pP]roject(?: "([^\"]+?)")? uses the following types:$/ do |project, table|
  project = get_project(project)

  types = table.raw.map do |line|
    name = line.first
    type = Type.find_by_name(name)

    type = FactoryGirl.create(:type, :name => name) if type.blank?
    type
  end

  project.update_attributes :type_ids => types.map(&:id).map(&:to_s)
end

Then(/^I should see the following fields:$/) do |table|
  table.rows.each do |field, value|
    # enforce matches including the value only if it is provided
    # i.e. the column in the table is created

    if value

      begin
        found = find_field(field)
      rescue Capybara::ElementNotFound
        raise Capybara::ExpectationNotMet, "expected to find field \"#{field}\" but there were no matches."
      end

      if found.tag_name == "select" && value.present?
        should have_select(field, :selected => value)
      else
        found.value.should == value
      end
    else
      should have_field(field)
    end
  end
end

