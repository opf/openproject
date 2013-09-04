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

Then /^I should see the "(.+)" image(?: within "([^\"]*)")?$/ do |image, selector|
  search_string = selector ? Nokogiri::CSS.xpath_for(selector).first + "//img[contains(@src,\"#{image}\")]" : "//img[contains(@src,\"#{image}\")]"
  page.should have_xpath(search_string)
end

Then /^I should not see the "(.+)" image(?: within "([^\"]*)")?$/ do |image, selector|
  search_string = selector ? Nokogiri::CSS.xpath_for(selector).first + "//img[contains(@src,\"#{image}\")]" : "//img[contains(@src,\"#{image}\")]"
  page.should have_no_xpath(search_string)
end

Then /^I should see an image$/ do
  img = find :css, 'img'
  img.should be_present
  img.should be_visible
end

