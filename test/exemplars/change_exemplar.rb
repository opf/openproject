class Change < ActiveRecord::Base
  generator_for :action => 'A'
  generator_for :path, :method => :next_path
  generator_for :changeset, :method => :generate_changeset

  def self.next_path
    @last_path ||= 'test/dir/aaa0001'
    @last_path.succ!
    @last_path
  end

  def self.generate_changeset
    Changeset.generate!
  end
end
