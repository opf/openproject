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

class EnabledModule < ActiveRecord::Base
  belongs_to :project

  attr_protected :project_id
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :project_id

  after_create :module_enabled

  private

  # after_create callback used to do things when a module is enabled
  def module_enabled
    case name
    when 'wiki'
      # Create a wiki with a default start page
      if project && project.wiki.nil?
        wiki = Wiki.create(:project => project, :start_page => 'Wiki')

        wiki_menu_item = WikiMenuItem.find_or_initialize_by_wiki_id_and_title(wiki.id, wiki.start_page)
        wiki_menu_item.name = 'Wiki'
        wiki_menu_item.new_wiki_page = true
        wiki_menu_item.index_page = true

        wiki_menu_item.save!
      end
    end
  end
end
