When /^(?:|I )follow first "([^"]*)"$/ do |link|
  first(:link, link).click
end