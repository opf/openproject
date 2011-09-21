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

class MergeWikiVersionsWithJournals < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the WikiContent::Version class has been removed
    unless WikiContent.const_defined?("Version")
      WikiContent.const_set("Version", Class.new(ActiveRecord::Base))
    end

    # avoid touching WikiContent on journal creation
    WikiContentJournal.class_exec {
      def touch_journaled_after_creation
      end
    }

    # assign all wiki_contents w/o author to the anonymous user - they used to
    # work w/o author but don't any more.
    WikiContent.update_all({:author_id => User.anonymous.id}, :author_id => nil)
    WikiContent::Version.update_all({:author_id => User.anonymous.id}, :author_id => nil)

    WikiContent::Version.find_by_sql("SELECT * FROM wiki_content_versions").each do |wv|
      journal = WikiContentJournal.create!(:journaled_id => wv.wiki_content_id, :user_id => wv.author_id,
        :notes => wv.comments, :created_at => wv.updated_on, :activity_type => "wiki_edits")
      changes = {}
      changes["compression"] = wv.compression
      changes["data"] = wv.data
      journal.update_attribute(:changes, changes.to_yaml)
      journal.update_attribute(:version, wv.version)
    end
    # drop_table :wiki_content_versions

    change_table :wiki_contents do |t|
      t.rename :version, :lock_version
    end
  end

  def self.down
    change_table :wiki_contents do |t|
      t.rename :lock_version, :version
    end

    # create_table :wiki_content_versions do |t|
    #   t.column :wiki_content_id, :integer, :null => false
    #   t.column :page_id, :integer, :null => false
    #   t.column :author_id, :integer
    #   t.column :data, :binary
    #   t.column :compression, :string, :limit => 6, :default => ""
    #   t.column :comments, :string, :limit => 255, :default => ""
    #   t.column :updated_on, :datetime, :null => false
    #   t.column :version, :integer, :null => false
    # end
    # add_index :wiki_content_versions, :wiki_content_id, :name => :wiki_content_versions_wcid
    #
    # WikiContentJournal.all.each do |j|
    #   WikiContent::Version.create(:wiki_content_id => j.journaled_id, :page_id => j.journaled.page_id,
    #     :author_id => j.user_id, :data => j.changes["data"], :compression => j.changes["compression"],
    #     :comments => j.notes, :updated_on => j.created_at, :version => j.version)
    # end

    WikiContentJournal.destroy_all
  end
end
