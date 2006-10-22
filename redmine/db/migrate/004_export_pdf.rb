class ExportPdf < ActiveRecord::Migration
  def self.up
    Permission.create :controller => "projects", :action => "export_issues_pdf", :description => "label_export_pdf", :sort => 1002, :is_public => true, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "issues", :action => "export_pdf", :description => "label_export_pdf", :sort => 1015, :is_public => true, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'export_issues_pdf']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'issues', 'export_pdf']).destroy
  end
end
