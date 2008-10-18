class AddDeleteWikiPagesAttachmentsPermission < ActiveRecord::Migration
  def self.up
	Role.find(:all).each do |r|
	  r.add_permission!(:delete_wiki_pages_attachments) if r.has_permission?(:edit_wiki_pages)
  	end
  end

  def self.down
	Role.find(:all).each do |r|
	  r.remove_permission!(:delete_wiki_pages_attachments)
  	end
  end
end
