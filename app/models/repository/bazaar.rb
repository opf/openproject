#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redmine/scm/adapters/bazaar_adapter'

class Repository::Bazaar < Repository
  attr_protected :root_url
  validates_presence_of :url, :log_encoding

  ATTRIBUTE_KEY_NAMES = {
      "url"          => "Root directory",
      "log_encoding" => "Commit messages encoding",
    }
  def self.human_attribute_name(attribute_key_name)
    ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
  end

  def self.scm_adapter_class
    Redmine::Scm::Adapters::BazaarAdapter
  end

  def self.scm_name
    'Bazaar'
  end

  def entries(path=nil, identifier=nil)
    entries = scm.entries(path, identifier)
    if entries
      entries.each do |e|
        next if e.lastrev.revision.blank?
        # Set the filesize unless browsing a specific revision
        if identifier.nil? && e.is_file?
          full_path = File.join(root_url, e.path)
          e.size = File.stat(full_path).size if File.file?(full_path)
        end
        c = Change.find(:first,
                        :include => :changeset,
                        :conditions => ["#{Change.table_name}.revision = ? and #{Changeset.table_name}.repository_id = ?", e.lastrev.revision, id],
                        :order => "#{Changeset.table_name}.revision DESC")
        if c
          e.lastrev.identifier = c.changeset.revision
          e.lastrev.name = c.changeset.revision
          e.lastrev.author = c.changeset.committer
        end
      end
    end
  end

  def fetch_changesets
    scm_info = scm.info
    if scm_info
      # latest revision found in database
      db_revision = latest_changeset ? latest_changeset.revision.to_i : 0
      # latest revision in the repository
      scm_revision = scm_info.lastrev.identifier.to_i
      if db_revision < scm_revision
        logger.debug "Fetching changesets for repository #{url}" if logger && logger.debug?
        identifier_from = db_revision + 1
        while (identifier_from <= scm_revision)
          # loads changesets by batches of 200
          identifier_to = [identifier_from + 199, scm_revision].min
          revisions = scm.revisions('', identifier_to, identifier_from, :with_paths => true)
          transaction do
            revisions.reverse_each do |revision|
              changeset = Changeset.create(:repository => self,
                                           :revision => revision.identifier,
                                           :committer => revision.author,
                                           :committed_on => revision.time,
                                           :scmid => revision.scmid,
                                           :comments => revision.message)

              revision.paths.each do |change|
                Change.create(:changeset => changeset,
                              :action => change[:action],
                              :path => change[:path],
                              :revision => change[:revision])
              end
            end
          end unless revisions.nil?
          identifier_from = identifier_to + 1
        end
      end
    end
  end
end
