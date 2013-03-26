Given /^there are no issues$/ do
  Issue.destroy_all
end

Given /^the issue "(.*?)" is watched by:$/ do |issue_subject, watchers|
  issue = Issue.find(:last, :conditions => {:subject => issue_subject}, :order => :created_on)
  watchers.raw.flatten.each {|w| issue.add_watcher User.find_by_login(w)}
  issue.save
end

Then /^the issue "(.*?)" should have (\d+) watchers$/ do |issue_subject, watcher_count|
  Issue.find_by_subject(issue_subject).watchers.count.should == watcher_count.to_i
end
