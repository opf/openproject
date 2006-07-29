desc 'Load default configuration data (using default language)'

task :load_default_data => :environment do
  include GLoc
  set_language_if_valid($RDM_DEFAULT_LANG)
  
  # roles
  r = Role.create :name => l(:default_role_manager) 
  r.permissions = Permission.find(:all, :conditions => ["is_public=?", false])
  r = Role.create :name => l(:default_role_developper)
  r.permissions = Permission.find(:all, :conditions => ["is_public=?", false])
  r = Role.create :name => l(:default_role_reporter)
  r.permissions = Permission.find(:all, :conditions => ["is_public=?", false])
  # trackers
  Tracker.create(:name => l(:default_tracker_bug), :is_in_chlog => true)
  Tracker.create(:name => l(:default_tracker_feature), :is_in_chlog => true)
  Tracker.create(:name => l(:default_tracker_support), :is_in_chlog => false)
  # issue statuses
  IssueStatus.create(:name => l(:default_issue_status_new), :is_closed => false, :is_default => true, :html_color => 'F98787')
  IssueStatus.create(:name => l(:default_issue_status_assigned), :is_closed => false, :is_default => false, :html_color => 'C0C0FF')
  IssueStatus.create(:name => l(:default_issue_status_resolved), :is_closed => false, :is_default => false, :html_color => '88E0B3')
  IssueStatus.create(:name => l(:default_issue_status_feedback), :is_closed => false, :is_default => false, :html_color => 'F3A4F4')
  IssueStatus.create(:name => l(:default_issue_status_closed), :is_closed => true, :is_default => false, :html_color => 'DBDBDB')
  IssueStatus.create(:name => l(:default_issue_status_rejected), :is_closed => true, :is_default => false, :html_color => 'F5C28B')
  # workflow
  Tracker.find(:all).each { |t|
    Role.find(:all).each { |r|
      IssueStatus.find(:all).each { |os|
        IssueStatus.find(:all).each { |ns|
          Workflow.create(:tracker_id => t.id, :role_id => r.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
        }        
      }      
    }
  }    
  # enumerations
  Enumeration.create(:opt => "DCAT", :name => l(:default_doc_category_user))
  Enumeration.create(:opt => "DCAT", :name => l(:default_doc_category_tech))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_low))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_normal))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_high))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_urgent))
  Enumeration.create(:opt => "IPRI", :name => l(:default_priority_immediate))
end