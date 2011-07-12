Then /^I want to use Firefox 5.0$/ do
  page.evaluate_script("window.navigator.appVersion").should =~ /^5\.0/
end
