desc 'Load default configuration data'

task :load_default_data => :environment do
  include GLoc
  set_language_if_valid('en')
  puts
  
  while true
    print "Select language: "
    print GLoc.valid_languages.sort {|x,y| x.to_s <=> y.to_s }.join(", ")
    print " [#{GLoc.current_language}] "
    lang = STDIN.gets.chomp!
    break if lang.empty?
    break if set_language_if_valid(lang)
    puts "Unknown language!"
  end
    
  puts "===================================="
  
begin
  # check that no data already exists
  if Role.find(:first)
    raise "Some roles are already defined."
  end
  if Tracker.find(:first)
    raise "Some trackers are already defined."
  end
  if IssueStatus.find(:first)
    raise "Some statuses are already defined."
  end
  if Enumeration.find(:first)
    raise "Some enumerations are already defined."
  end
    
  puts "Loading default configuration data for language: #{current_language}"
 
  # roles
  manager = Role.create :name => l(:default_role_manager), :position => 1
  manager.permissions = Permission.find(:all, :conditions => ["is_public=?", false])
  
  developper = Role.create :name => l(:default_role_developper), :position => 2
  perms = [150, 320, 321, 322, 420, 421, 422, 1050, 1060, 1070, 1075, 1130, 1220, 1221, 1222, 1223, 1224, 1320, 1322, 1061, 1057, 1520]
  developper.permissions = Permission.find(:all, :conditions => ["sort IN (#{perms.join(',')})"])
  
  reporter = Role.create :name => l(:default_role_reporter), :position => 3
  perms = [1050, 1060, 1070, 1057, 1130]
  reporter.permissions = Permission.find(:all, :conditions => ["sort IN (#{perms.join(',')})"])
  
  # trackers
  Tracker.create(:name => l(:default_tracker_bug), :is_in_chlog => true, :is_in_roadmap => false, :position => 1)
  Tracker.create(:name => l(:default_tracker_feature), :is_in_chlog => true, :is_in_roadmap => true, :position => 2)
  Tracker.create(:name => l(:default_tracker_support), :is_in_chlog => false, :is_in_roadmap => false, :position => 3)
  
  # issue statuses
  new       = IssueStatus.create(:name => l(:default_issue_status_new), :is_closed => false, :is_default => true, :html_color => 'F98787', :position => 1)
  assigned  = IssueStatus.create(:name => l(:default_issue_status_assigned), :is_closed => false, :is_default => false, :html_color => 'C0C0FF', :position => 2)
  resolved  = IssueStatus.create(:name => l(:default_issue_status_resolved), :is_closed => false, :is_default => false, :html_color => '88E0B3', :position => 3)
  feedback  = IssueStatus.create(:name => l(:default_issue_status_feedback), :is_closed => false, :is_default => false, :html_color => 'F3A4F4', :position => 4)
  closed    = IssueStatus.create(:name => l(:default_issue_status_closed), :is_closed => true, :is_default => false, :html_color => 'DBDBDB', :position => 5)
  rejected  = IssueStatus.create(:name => l(:default_issue_status_rejected), :is_closed => true, :is_default => false, :html_color => 'F5C28B', :position => 6)
  
  # workflow
  Tracker.find(:all).each { |t|
    IssueStatus.find(:all).each { |os|
      IssueStatus.find(:all).each { |ns|
        Workflow.create(:tracker_id => t.id, :role_id => manager.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
      }        
    }      
  }
  
  Tracker.find(:all).each { |t|
    [new, assigned, resolved, feedback].each { |os|
      [assigned, resolved, feedback, closed].each { |ns|
        Workflow.create(:tracker_id => t.id, :role_id => developper.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
      }        
    }      
  }
  
  Tracker.find(:all).each { |t|
    [new, assigned, resolved, feedback].each { |os|
      [closed].each { |ns|
        Workflow.create(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
      }        
    }
    Workflow.create(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => resolved.id, :new_status_id => feedback.id)
  }

  # enumerations
  Enumeration.create(:opt => "DCAT", :name => l(:default_doc_category_user))
  Enumeration.create(:opt => "DCAT", :name => l(:default_doc_category_tech))

  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_low))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_normal))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_high))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_urgent))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_immediate))

  Enumeration.create(:opt => "ACTI", :name => l(:default_activity_design))
  Enumeration.create(:opt => "ACTI", :name => l(:default_activity_development))
 
rescue => error
  puts "Error: " + error
  puts "Default configuration data can't be loaded."
end
end