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
