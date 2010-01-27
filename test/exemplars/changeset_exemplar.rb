class Changeset < ActiveRecord::Base
  generator_for :revision, :method => :next_revision
  generator_for :committed_on => Date.today
  generator_for :repository, :method => :generate_repository

  def self.next_revision
    @last_revision ||= '1'
    @last_revision.succ!
    @last_revision
  end

  def self.generate_repository
    Repository::Subversion.generate!
  end
end
