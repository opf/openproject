class FixMessagesStickyNull < ActiveRecord::Migration
  def self.up
    Message.update_all('sticky = 0', 'sticky IS NULL')
  end

  def self.down
    # nothing to do
  end
end
