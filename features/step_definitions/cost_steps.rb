# Try to find a user with the login or roletype and log in using that user
Given /^I am(?: a)? "([^\"]*)"$/ do |login_or_role|
  User.current = User.find_by_login(login_or_role) or Role.find_by_name(login_or_role).members.first.user
  steps %Q{
    Given I am logged in as "#{u.login}"
  }
end

# If the named or current user is not already a member of the project, add him with his 
# primary role
Given /^(?:the user "([^\"]+)" is|I am)(?: a)? member of "([^\"]+)"$/ do |username, projectname|
  p = Project.find_by_name(projectname)
  user = username ? User.find_by_login(username) : User.current
  unless p.members.detect {|m| m.user == user}
    steps %Q{
      The user #{user.login} is a "#{user.roles.first.name}" in project "#{projectname}"
    }
  end
end

Given /^(?:the user "([^\"]+)" is|I am)(?: a)? member of "([^\"]+)":$/ do |username, projectname, table|
  steps %Q{
    The user #{user.login} is a "#{user.roles.first.name}" in project "#{projectname}"
  }
  user = username ? User.find_by_login(username) : User.current
  p = Project.find_by_name(projectname)
  if tables[/[hH]ourly [rR]ate/]
    hr = HourlyRate.new.tap do |r|
      r.project = p
      r.user = user
      r.valid_from = 1.year.ago
      r.rate = tables[/[hH]ourly [rR]ate/][1].to_i
      r.save!
    end
  end
end

# Add a "material" cost entry (which is just our standard cost entry) or a time entry to the last issue
Given /^(?:this issue|the issue "([^\"]+)") has (\d+) (?:([Tt]ime)|(?:(?:[Mm]aterial\s?)?[cC]ost))\s?[eE]?ntry with the following:$/ do |time, type, count|
  owner = subject ? Issue.find_by_subject(subject) : Issue.last
  klass = time ? TimeEntry : CostEntry
  count.times do
    ce = klass.spawn
    table.rows_hash.each do |key, value|
      if key =~ /[uU]ser/
        ce.user = value =~ /me|I|myself/ ? User.current : User.find_by_login(value)
      elsif key =~ /[cC]ost\s?[tT]ype/
        ce.cost_type = CostType.find_by_name(value)
      else
        ce.send(:"#{key}=", value)
      end
    end
    ce.project = owner.project
    ce.save!
    owner.cost_entries << ce
  end
end

# Possibly add the current user to the project and set his hourly rate
Given /^I am(?: a)? member of "([^\"]+)":$/ do |projectname, fields|
  steps %Q{
    Given I am a member of "#{projectname}"
  }
  fields.rows_hash.each do |key, value|
    if key.gsub(" ", "_").underscore == "hourly_rate"
      HourlyRate.create! :rate => value,
                         :user => User.find(5), 
                         :project => Project.first,
                         :valid_from => Date.today
    end
  end
end

Given /^the (?:([Uu]ser)|([Pp]roject))(?: named| with(?: the)? name| called)? "([^\"]*)" has (only )?(\d+|[a-z]+) [cC]ost\s?[eE]ntr(?:y|ies)$/ do |user, project, name, do_delete_all, count|
  steps %Q{
    Given the #{"user" if user}#{"project" if project} "#{name}" has #{"only " if do_delete_all}#{count} cost entries with the following:
      | |
  }
end

Given /^the (?:([Uu]ser)|([Pp]roject))(?: named| with(?: the)? name| called)? "([^\"]*)" has (only )?(\d+|[a-z]+) [cC]ost\s?[eE]ntr(?:y|ies) with the following:$/ do |user, project, name, do_delete_all, count, table|
  count = 1 if count == "one"
  count = (count || 1).to_i
  
  u = user ? User.find_by_login(name) : u = User.find_by_login("admin")
  p = project ? Project.find_by_name(name) : u.members.last.project
  
  if do_delete_all
    CostEntry.find(:all, :conditions => ["project_id = #{p.id}"]).each do |c|
      c.destroy
    end
  end
  
  count.times do
    as_admin do
      CostEntry.spawn.tap do |i|
        i.project = p
        i.issue = Issue.generate_for_project!(p)
        i.user = u
        unless table.raw.first.first.blank? # if we get an empty table, ignore that
          table.rows_hash.each do |field,value|
            field = field.gsub(" ", "_").underscore.to_sym
            old_val = i.send(field)
            i.send(:"#{field}=", value)
            i.send(:"#{field}=", old_val) unless i.save
          end
        end
      end.save!
    end
  end
end

Given /^the (?:project|Project)(?: named| with(?: the)? name| called)? "([^\"]*)" has (only )?(\d+|[a-z]+) [cC]ost\s?[eE]ntr(?:y|ies)$/ do |name, do_delete_all, count|
  steps %Q{
    Given the project "#{name}" has #{"only " if do_delete_all}#{count} cost entries with the following:
      | |
  }
end

Given /^there (?:is|are)( only)? (\d+) [Uu]ser[s]? with:$/ do |do_delete_all, count, fields|
  rate_regex = /[dD]efault\s?[rR]ate/
  new_table = fields.reject_key(rate_regex)
  if do_delete_all
    admin = User.find_by_login("admin")
    anonymous = AnonymousUser.first
    User.delete_all
    admin.save!
    anonymous.save!
  end
  users = create_some_objects(count, false, "User", new_table)
  users.each do |u|
    u.hashed_password = User.hash_password("admin")
    unless new_table.raw.length == fields.raw.length
      fields.rows_hash.each do |k,v|
        if k =~ rate_regex
          rate = DefaultHourlyRate.new.tap do |r|
            r.valid_from = Date.today
            r.rate = v
            r.user = u
          end
          rate.save!
        end
      end
    end
    u.save!
  end
end

Given /^there is a standard cost control project named "([^\"]*)"$/ do |name|
  steps %Q{
    Given there is one project with the following:
      | Name | #{name} |
    And the project "#{name}" has 1 subproject
    And the role "Manager" may have the following rights:
      | View own cost entries |
    And the role "Controller" may have the following rights:
      | View own cost entries |
    And the role "Developer" may have the following rights:
      | View own cost entries |
    And the role "Reporter" may have the following rights:
      | Create issues |
    And the role "Supplier" may have the following rights:
      | View own hourly rate |
      | View own cost entries |
    And there is one user with the following:
      | Login | manager |
		And the user "manager" is a "Manager" in the project called "#{name}"
		And there is one user with the following:
      | Login | controller |
		And the user "controller" is a "Controller" in the project called "#{name}"
		And there is one user with the following:
      | Login | developer |
		And the user "developer" is a "Developer" in the project called "#{name}"
		And there is one user with the following:
      | Login | reporter |
		And the user "reporter" is a "Reporter" in the project called "#{name}"
		And there are 2..5 cost types in project "#{name}"
		And there are 2..5 cost types in project "#{name} Sub"
		And there are 5..10 issues in project "#{name}"
  }
end