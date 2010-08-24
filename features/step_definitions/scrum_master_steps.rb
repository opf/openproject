#
# Background steps
#

Given /^I am a scum master of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_scrum_master
end

#
# Scenario steps
#

Given /^I want to edit the sprint named (.+)$/ do |name|
  sprint = Sprint.find(:first, :conditions => "name='#{name}'")
  sprint.should_not be_nil
  @sprint_params = sprint.attributes
end

Given /^I want to set the (.+) of the sprint to (.+)$/ do |attribute, value|
  @sprint_params[attribute] = value
end

When /^I update the sprint$/ do
  page.driver.process :post,
                      url_for(:controller => 'backlogs', :action => 'update'),
                      @sprint_params
end

Then /^the sprint should be updated accordingly$/ do
  sprint = Sprint.find(@sprint_params['id'])
  
  sprint.attributes.each_key do |key|
    unless ['updated_on', 'created_on'].include?(key)
      @sprint_params[key].should == (key.include?('_date') ? sprint[key].strftime("%Y-%m-%d") : sprint[key])
    end
  end
end

def login_as_scrum_master
  visit url_for(:controller => 'account', :action=>'login')
  fill_in 'username', :with => 'jsmith'
  fill_in 'password', :with => 'jsmith'
  click_button 'Login »'
  @user = User.find(:first, :conditions => "login='jsmith'")
end
