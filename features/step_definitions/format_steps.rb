Then /^there should be a link to the issue list in ([^ ]+) format$/ do |format|
  find_link(format)[:href].should == project_issues_path(:project_id => 1, :format => 'xls')
end
