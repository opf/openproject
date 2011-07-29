class RemoveDoubleInitialWikiContentJournals < ActiveRecord::Migration
  def self.up
    # Remove the newest initial WikiContentJournal (the one erroneously created by a former migration) if there are more than one
    WikiContentJournal.find(:all, :conditions => {:version => 1}).group_by(&:journaled_id).select {|k,v| v.size > 1}.each {|k,v| v.max_by(&:created_at).delete}
  end

  def self.down
    # noop
  end
end
