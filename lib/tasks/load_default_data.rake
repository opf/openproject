desc 'Load default configuration data (using default language)'

task :load_default_data => :environment do
  include GLoc
  set_language_if_valid($RDM_DEFAULT_LANG)

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
    
  puts "Loading default configuration for language: #{current_language}"
 
  # roles
  manager = Role.create :name => l(:default_role_manager) 
  manager.permissions = Permission.find(:all, :conditions => ["is_public=?", false])
  
  developper = Role.create :name => l(:default_role_developper)
  perms = [150, 320, 321, 322, 420, 421, 422, 1050, 1060, 1070, 1075, 1220, 1221, 1222, 1223, 1224, 1320, 1322, 1061, 1057]
  developper.permissions = Permission.find(:all, :conditions => ["sort IN (#{perms.join(',')})"])
  
  reporter = Role.create :name => l(:default_role_reporter)
  perms = [1050, 1060, 1070, 1057]
  reporter.permissions = Permission.find(:all, :conditions => ["sort IN (#{perms.join(',')})"])
  
  # trackers
  Tracker.create(:name => l(:default_tracker_bug), :is_in_chlog => true)
  Tracker.create(:name => l(:default_tracker_feature), :is_in_chlog => true)
  Tracker.create(:name => l(:default_tracker_support), :is_in_chlog => false)
  
  # issue statuses
  new       = IssueStatus.create(:name => l(:default_issue_status_new), :is_closed => false, :is_default => true, :html_color => 'F98787')
  assigned  = IssueStatus.create(:name => l(:default_issue_status_assigned), :is_closed => false, :is_default => false, :html_color => 'C0C0FF')
  resolved  = IssueStatus.create(:name => l(:default_issue_status_resolved), :is_closed => false, :is_default => false, :html_color => '88E0B3')
  feedback  = IssueStatus.create(:name => l(:default_issue_status_feedback), :is_closed => false, :is_default => false, :html_color => 'F3A4F4')
  closed    = IssueStatus.create(:name => l(:default_issue_status_closed), :is_closed => true, :is_default => false, :html_color => 'DBDBDB')
  rejected  = IssueStatus.create(:name => l(:default_issue_status_rejected), :is_closed => true, :is_default => false, :html_color => 'F5C28B')
  
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
  
rescue => error
  puts "Error: " + error
  puts "Default configuration can't be loaded."
end
end