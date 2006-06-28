class DefaultConfiguration < ActiveRecord::Migration
  def self.up
    # roles
    r = Role.create(:name => "Manager")
    r.permissions = Permission.find(:all)
    r = Role.create :name => "Developer"
    r.permissions = Permission.find([1, 2, 3, 6, 10, 11, 12, 16, 17, 18, 19, 20, 21, 23, 25, 26, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41])
    r = Role.create :name => "Reporter"
    r.permissions = Permission.find([1, 2, 3, 6, 16, 17, 18, 19, 20, 21, 23, 25, 26, 30, 31, 32, 38, 39])
    # trackers
    Tracker.create(:name => "Bug", :is_in_chlog => true)
    Tracker.create(:name => "Feature request", :is_in_chlog => true)
    Tracker.create(:name => "Support request", :is_in_chlog => false)
    # issue statuses
    IssueStatus.create(:name => "New", :is_closed => false, :is_default => true, :html_color => 'F98787')
    IssueStatus.create(:name => "Assigned", :is_closed => false, :is_default => false, :html_color => 'C0C0FF')
    IssueStatus.create(:name => "Resolved", :is_closed => false, :is_default => false, :html_color => '88E0B3')
    IssueStatus.create(:name => "Feedback", :is_closed => false, :is_default => false, :html_color => 'F3A4F4')
    IssueStatus.create(:name => "Closed", :is_closed => true, :is_default => false, :html_color => 'DBDBDB')
    IssueStatus.create(:name => "Rejected", :is_closed => true, :is_default => false, :html_color => 'F5C28B')
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
    # enumeartions
    Enumeration.create(:opt => "DCAT", :name => 'Uncategorized')
    Enumeration.create(:opt => "DCAT", :name => 'User documentation')
    Enumeration.create(:opt => "DCAT", :name => 'Technical documentation')
    Enumeration.create(:opt => "IPRI", :name => 'Low')
    Enumeration.create(:opt => "IPRI", :name => 'Normal')
    Enumeration.create(:opt => "IPRI", :name => 'High')
    Enumeration.create(:opt => "IPRI", :name => 'Urgent')
    Enumeration.create(:opt => "IPRI", :name => 'Immediate')
  end

  def self.down
  end
end
