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

Given /^there are no issues$/ do
  Issue.destroy_all
end

Given /^the issue "(.*?)" is watched by:$/ do |issue_subject, watchers|
  issue = Issue.find(:last, :conditions => {:subject => issue_subject}, :order => :created_at)
  watchers.raw.flatten.each {|w| issue.add_watcher User.find_by_login(w)}
  issue.save
end

Then /^the issue "(.*?)" should have (\d+) watchers$/ do |issue_subject, watcher_count|
  Issue.find_by_subject(issue_subject).watchers.count.should == watcher_count.to_i
end

Given(/^the issue "(.*?)" has an attachment "(.*?)"$/) do |issue_subject, file_name|
  issue = Issue.find(:last, :conditions => {:subject => issue_subject}, :order => :created_at)
  attachment = FactoryGirl.create :attachment,
        :author => issue.author,
        :content_type => 'image/gif',
        :filename => file_name,
        :disk_filename => "#{rand(10000000..99999999)}_#{file_name}",
        :digest => Digest::MD5.hexdigest(file_name),
        :container => issue,
        :filesize => rand(100..10000),
        :description => 'This is an attachment description'
end

When(/^I click the first delete attachment link$/) do
  delete_link = find :xpath, "//a[@title='Delete'][1]"
  delete_link.click
end
