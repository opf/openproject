class UpdateEnumerationsToSti < ActiveRecord::Migration
  def self.up
    Enumeration.update_all("type = 'IssuePriority'", "opt = 'IPRI'")
    Enumeration.update_all("type = 'DocumentCategory'", "opt = 'DCAT'")
    Enumeration.update_all("type = 'TimeEntryActivity'", "opt = 'ACTI'")
  end

  def self.down
    # no-op
  end
end
