Given /^the (?:project|Project)(?: named| with(?: the)? name| called)? "([^\"]*)" has (only )?(\d+|[a-z]+) [cC]ost\s?[eE]ntr(?:y|ies) with the following:$/ do |name, do_delete_all, count,  table|
  count = 1 if count == "one"
  count = (count || 1).to_i
  
  p = Project.find_by_name(name)
  
  if do_delete_all
    CostEntry.find(:all, :conditions => ["project_id = #{p.id}"]).each do |c|
      c.destroy
    end
  end
  
  count.times do 
    CostEntry.spawn.tap do |i|
      i.project = p
      i.issue = Issue.generate_for_project!(p)
      
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

Given /^the (?:project|Project)(?: named| with(?: the)? name| called)? "([^\"]*)" has (only )?(\d+|[a-z]+) [cC]ost\s?[eE]ntr(?:y|ies)$/ do |name, do_delete_all, count|
  steps %Q{
    Given the project "#{name}" has #{"only " if do_delete_all}#{count} cost entries with the following:
      | |
  }
end

Given /^there is a standard cost control project named "([^\"]*)"$/ do |name|
  steps %Q{
    Given there is one project with the following:
      | Name | #{name} |
    And there is 1 subproject for the project #{name}
    And the role "Manager" may have the following rights in project "#{name}":
      |  |
    And the role "Controller" may have the following rights in project "#{name}":
      |  |
    And the role "Developer" may have the following rights in project "#{name}":
      |  |
    And the role "Reporter" may have the following rights in project "#{name}":
      |  |
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