#-- encoding: UTF-8
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
