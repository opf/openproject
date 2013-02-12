Then /^the "([^"]*)" link should point to "([^"]*)"$/ do |title, target|
  node = page.find(:xpath, "//a[contains(.,'#{title}')]")
  node['href'].should == target
end
