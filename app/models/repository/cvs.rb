#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redmine/scm/adapters/cvs_adapter'
require 'digest/sha1'

class Repository::Cvs < Repository
  validates_presence_of :url, :root_url, :log_encoding

  ATTRIBUTE_KEY_NAMES = {
      "url"          => "CVSROOT",
      "root_url"     => "Module",
      "log_encoding" => "Commit messages encoding",
    }
  def self.human_attribute_name(attribute_key_name)
    ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
  end

  def self.scm_adapter_class
    Redmine::Scm::Adapters::CvsAdapter
  end

  def self.scm_name
    'CVS'
  end

  def entry(path=nil, identifier=nil)
    rev = identifier.nil? ? nil : changesets.find_by_revision(identifier)
    scm.entry(path, rev.nil? ? nil : rev.committed_on)
  end

  def entries(path=nil, identifier=nil)
    rev = identifier.nil? ? nil : changesets.find_by_revision(identifier)
    entries = scm.entries(path, rev.nil? ? nil : rev.committed_on)
    if entries
      entries.each() do |entry|
        if ( ! entry.lastrev.nil? ) && ( ! entry.lastrev.revision.nil? )
          change=changes.find_by_revision_and_path(
                     entry.lastrev.revision,
                     scm.with_leading_slash(entry.path) )
          if change
            entry.lastrev.identifier = change.changeset.revision
            entry.lastrev.revision   = change.changeset.revision
            entry.lastrev.author     = change.changeset.committer
            # entry.lastrev.branch     = change.branch
          end
        end
      end
    end
    entries
  end

  def cat(path, identifier=nil)
    rev = identifier.nil? ? nil : changesets.find_by_revision(identifier)
    scm.cat(path, rev.nil? ? nil : rev.committed_on)
  end

  def diff(path, rev, rev_to)
    #convert rev to revision. CVS can't handle changesets here
    diff=[]
    changeset_from=changesets.find_by_revision(rev)
    if rev_to.to_i > 0
      changeset_to=changesets.find_by_revision(rev_to)
    end
    changeset_from.changes.each() do |change_from|

      revision_from=nil
      revision_to=nil

      revision_from=change_from.revision if path.nil? || (change_from.path.starts_with? scm.with_leading_slash(path))

      if revision_from
        if changeset_to
          changeset_to.changes.each() do |change_to|
            revision_to=change_to.revision if change_to.path==change_from.path
          end
        end
        unless revision_to
          revision_to=scm.get_previous_revision(revision_from)
        end
        file_diff = scm.diff(change_from.path, revision_from, revision_to)
        diff = diff + file_diff unless file_diff.nil?
      end
    end
    return diff
  end

  def fetch_changesets
    # some nifty bits to introduce a commit-id with cvs
    # natively cvs doesn't provide any kind of changesets, there is only a revision per file.
    # we now take a guess using the author, the commitlog and the commit-date.

    # last one is the next step to take. the commit-date is not equal for all
    # commits in one changeset. cvs update the commit-date when the *,v file was touched. so
    # we use a small delta here, to merge all changes belonging to _one_ changeset
    time_delta=10.seconds

    fetch_since = latest_changeset ? latest_changeset.committed_on : nil
    transaction do
      tmp_rev_num = 1
      scm.revisions('', fetch_since, nil, :with_paths => true) do |revision|
        # only add the change to the database, if it doen't exists. the cvs log
        # is not exclusive at all.
        tmp_time = revision.time.clone
        unless changes.find_by_path_and_revision(
	           scm.with_leading_slash(revision.paths[0][:path]), revision.paths[0][:revision])
          cmt = Changeset.normalize_comments(revision.message, repo_log_encoding)
          cs = changesets.find(:first, :conditions=>{
            :committed_on=>tmp_time - time_delta .. tmp_time + time_delta,
            :committer=>revision.author,
            :comments=>cmt
          })

          # create a new changeset....
          unless cs
            # we use a temporaray revision number here (just for inserting)
            # later on, we calculate a continous positive number
            tmp_time2 = tmp_time.clone.gmtime
            branch = revision.paths[0][:branch]
            scmid = branch + "-" + tmp_time2.strftime("%Y%m%d-%H%M%S")
            cs = Changeset.create(:repository => self,
                                  :revision => "tmp#{tmp_rev_num}",
                                  :scmid => scmid,
                                  :committer => revision.author,
                                  :committed_on => tmp_time,
                                  :comments => revision.message)
            tmp_rev_num += 1
          end

          #convert CVS-File-States to internal Action-abbrevations
          #default action is (M)odified
          action="M"
          if revision.paths[0][:action]=="Exp" && revision.paths[0][:revision]=="1.1"
            action="A" #add-action always at first revision (= 1.1)
          elsif revision.paths[0][:action]=="dead"
            action="D" #dead-state is similar to Delete
          end

          Change.create(:changeset => cs,
          :action => action,
          :path => scm.with_leading_slash(revision.paths[0][:path]),
          :revision => revision.paths[0][:revision],
          :branch => revision.paths[0][:branch]
          )
        end
      end

      # Renumber new changesets in chronological order
      changesets.find(
              :all, :order => 'committed_on ASC, id ASC', :conditions => "revision LIKE 'tmp%'"
           ).each do |changeset|
        changeset.update_attribute :revision, next_revision_number
      end
    end # transaction
    @current_revision_number = nil
  end

  private

  # Returns the next revision number to assign to a CVS changeset
  def next_revision_number
    # Need to retrieve existing revision numbers to sort them as integers
    sql = "SELECT revision FROM #{Changeset.table_name} "
    sql << "WHERE repository_id = #{id} AND revision NOT LIKE 'tmp%'"
    @current_revision_number ||= (connection.select_values(sql).collect(&:to_i).max || 0)
    @current_revision_number += 1
  end
end
