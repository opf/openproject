class FixDifferencesBetweenSchemaRbs < ActiveRecord::Migration
  def self.up
    # duplicate surviving indices differ on mysql and postgres, remove all of them
    duplicate_indices = [:index_journals_on_journalized_id,
                         :index_journals_on_created_on,
                         :journals_journalized_id,
                         :index_journals_on_journaled_id,
                         :index_journals_on_created_at]

    duplicate_indices.each do |index_name|
      begin
        remove_index :journals, :name => index_name
      rescue ArgumentError
        # don't care if index is not present. postgres doesn't have them all
        # because it's smart enough to know that we don't want two differently
        # named indices twice when they are actually the same. bazinga!
      end
    end

    # re-add the ones needed
    add_index :journals, :created_at
    add_index :journals, :journaled_id

    # the following reverts a migration (20091227112908_change_wiki_contents_text_limit)
    # which added a limit to the two columns for mysql only which results in different
    # schema.rbs. it wasn't done for postgres because it failed back in 2009, now postgres
    # just ignores it. since it wasn't done for postgres it can't be that important, right?!
    if ChiliProject::Database.mysql?
      change_column :wiki_contents, :text, :text
      change_column :wiki_content_versions, :data, :binary
    end
  end

  def self.down
    # no need for messing with the indices, #up only removes duplicates from schema.rb
    # we don't want to re-add them...

    # but hey, give mysql its limits back!
    if ChiliProject::Database.mysql?
      max_size = 16.megabytes
      change_column :wiki_contents, :text, :text, :limit => max_size
      change_column :wiki_content_versions, :data, :binary, :limit => max_size
    end
  end
end
