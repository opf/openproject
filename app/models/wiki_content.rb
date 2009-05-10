# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'zlib'

class WikiContent < ActiveRecord::Base
  set_locking_column :version
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'page_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  validates_presence_of :text
  validates_length_of :comments, :maximum => 255, :allow_nil => true
  
  acts_as_versioned
  class Version
    belongs_to :page, :class_name => '::WikiPage', :foreign_key => 'page_id'
    belongs_to :author, :class_name => '::User', :foreign_key => 'author_id'
    attr_protected :data

    acts_as_event :title => Proc.new {|o| "#{l(:label_wiki_edit)}: #{o.page.title} (##{o.version})"},
                  :description => :comments,
                  :datetime => :updated_on,
                  :type => 'wiki-page',
                  :url => Proc.new {|o| {:controller => 'wiki', :id => o.page.wiki.project_id, :page => o.page.title, :version => o.version}}

    acts_as_activity_provider :type => 'wiki_edits',
                              :timestamp => "#{WikiContent.versioned_table_name}.updated_on",
                              :author_key => "#{WikiContent.versioned_table_name}.author_id",
                              :permission => :view_wiki_edits,
                              :find_options => {:select => "#{WikiContent.versioned_table_name}.updated_on, #{WikiContent.versioned_table_name}.comments, " +
                                                           "#{WikiContent.versioned_table_name}.#{WikiContent.version_column}, #{WikiPage.table_name}.title, " +
                                                           "#{WikiContent.versioned_table_name}.page_id, #{WikiContent.versioned_table_name}.author_id, " +
                                                           "#{WikiContent.versioned_table_name}.id",
                                                :joins => "LEFT JOIN #{WikiPage.table_name} ON #{WikiPage.table_name}.id = #{WikiContent.versioned_table_name}.page_id " +
                                                          "LEFT JOIN #{Wiki.table_name} ON #{Wiki.table_name}.id = #{WikiPage.table_name}.wiki_id " +
                                                          "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Wiki.table_name}.project_id"}

    def text=(plain)
      case Setting.wiki_compression
      when 'gzip'
      begin
        self.data = Zlib::Deflate.deflate(plain, Zlib::BEST_COMPRESSION)
        self.compression = 'gzip'
      rescue
        self.data = plain
        self.compression = ''
      end
      else
        self.data = plain
        self.compression = ''
      end
      plain
    end
    
    def text
      @text ||= case compression
      when 'gzip'
         Zlib::Inflate.inflate(data)
      else
        # uncompressed data
        data
      end      
    end
    
    def project
      page.project
    end
    
    # Returns the previous version or nil
    def previous
      @previous ||= WikiContent::Version.find(:first, 
                                              :order => 'version DESC',
                                              :include => :author,
                                              :conditions => ["wiki_content_id = ? AND version < ?", wiki_content_id, version])
    end
  end
  
end
