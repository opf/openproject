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