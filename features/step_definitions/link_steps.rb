When /^(?:|I )follow "([^\"]*)"(?: within "([^\"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

Then /^the "([^"]*)" link should point to "([^"]*)"$/ do |title, target|
  node = page.find(:xpath, "//a[contains(.,'#{title}')]")
  node['href'].should == target
end
