Then /^I should see the "(.+)" image(?: within "([^\"]*)")?$/ do |image, selector|
  search_string = selector ? Nokogiri::CSS.xpath_for(selector).first + "//img[contains(@src,\"#{image}\")]" : "//img[contains(@src,\"#{image}\")]"
  page.should have_xpath(search_string)
end

Then /^I should not see the "(.+)" image(?: within "([^\"]*)")?$/ do |image, selector|
  search_string = selector ? Nokogiri::CSS.xpath_for(selector).first + "//img[contains(@src,\"#{image}\")]" : "//img[contains(@src,\"#{image}\")]"
  page.should have_no_xpath(search_string)
end

Then /^I should see an image(?: within "(.+?)")$/ do |selector|
  with_scope(selector) do
    img = find :css, 'img'
    img.should be_present
    img.should be_visible
  end
end

