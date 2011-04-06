Given /^there is 1 [Mm]eeting in project "(.+)" created by "(.+)" with:$/ do |project,user,table|
  m = Factory.build(:meeting)
  m.project = Project.find_by_name(project)
  m.author  = User.find_by_login(user)
  send_table_to_object(m, table)
end

Given /^the [Mm]eeting "(.+)" has 1 agenda with:$/ do |meeting,table|
  m = Meeting.find_by_title(meeting)
  m.agenda ||= Factory.build(:meeting_agenda)
  send_table_to_object(m.agenda, table)
end

Given /^the [Mm]eeting "(.+)" has minutes with:$/ do |meeting,table|
  m = Meeting.find_by_title(meeting)
  m.minutes = Factory.build(:meeting_minutes)
  send_table_to_object(m.minutes, table)
end

Given /^"(.+)" is invited to the [Mm]eeting "(.+)"$/ do |user,meeting|
  m = Meeting.find_by_title(meeting)
  p = m.participants.detect{|p| p.user_id = User.find_by_login(user).id} || Factory.build(:meeting_participant, :meeting => m)
  p.invited = true
  p.save
end

Given /^"(.+)" attended the [Mm]eeting "(.+)"$/ do |user,meeting|
  m = Meeting.find_by_title(meeting)
  p = m.participants.detect{|p| p.user_id = User.find_by_login(user).id} || Factory.build(:meeting_participant, :meeting => m)
  p.attended = true
  p.save
end