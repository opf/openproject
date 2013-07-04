#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class MergeWikiVersionsWithJournals < ActiveRecord::Migration
  # This is provided here for migrating up after the WikiContent::Version class has been removed
  class WikiContent < ActiveRecord::Base
    class Version < ActiveRecord::Base
    end
  end

  def self.up
    # avoid touching WikiContent on journal creation
    WikiContentJournal.class_exec {
      def touch_journaled_after_creation
      end
    }

    # reload the user table schema is needed since
    # the mail_notification type was changed from bool to string
    User.connection.schema_cache.clear!
    User.reset_column_information
    ano_user = User.anonymous

    # assign all wiki_contents w/o author to the anonymous user - they used to
    # work w/o author but don't any more.
    WikiContent.update_all({:author_id => ano_user.id}, :author_id => nil)
    WikiContent::Version.update_all({:author_id => ano_user.id}, :author_id => nil)

    WikiContent::Version.find_by_sql("SELECT * FROM wiki_content_versions").each do |wv|
      journal = WikiContentJournal.create!(:journaled_id => wv.wiki_content_id, :user_id => wv.author_id,
        :notes => wv.comments, :created_at => wv.updated_on, :activity_type => "wiki_edits")
      changed_data = {}
      changed_data["compression"] = wv.compression
      changed_data["data"] = wv.data
      if journal.has_attribute? :changes
        journal.update_attribute(:changes, changed_data)
      else
        journal.update_attribute(:changed_data, changed_data)
      end
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
    #     :author_id => j.user_id, :data => j.changed_data["data"], :compression => j.changed_data["compression"],
    #     :comments => j.notes, :updated_on => j.created_at, :version => j.version)
    # end

    WikiContentJournal.destroy_all
  end
end
