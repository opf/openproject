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
  
  acts_as_versioned
  class Version
    belongs_to :page, :class_name => '::WikiPage', :foreign_key => 'page_id'
    belongs_to :author, :class_name => '::User', :foreign_key => 'author_id'
    attr_protected :data

    acts_as_event :title => Proc.new {|o| "#{l(:label_wiki_edit)}: #{o.page.title} (##{o.version})"},
                  :description => :comments,
                  :datetime => :updated_on,
                  :url => Proc.new {|o| {:controller => 'wiki', :id => o.page.wiki.project_id, :page => o.page.title, :version => o.version}}

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
  end
  
end
