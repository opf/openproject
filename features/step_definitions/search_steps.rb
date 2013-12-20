When /^I search globally for "([^"]*)"$/ do |query|
  steps %Q{
    And I fill in "stuff" for "q"
    And I press the "return" key on element "#q"
  }
end

When /^I search for "([^"]*)" after having searched$/ do |query|
  steps %Q{
    And I fill in "stuff" for "q" within "#content"
    And I press "Submit" within "#content"
  }
end