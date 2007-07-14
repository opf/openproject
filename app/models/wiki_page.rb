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

require 'diff'

class WikiPage < ActiveRecord::Base
  belongs_to :wiki
  has_one :content, :class_name => 'WikiContent', :foreign_key => 'page_id', :dependent => :destroy
  has_many :attachments, :as => :container, :dependent => :destroy
  
  validates_presence_of :title
  validates_format_of :title, :with => /^[^,\.\/\?\;\|\s]*$/
  validates_uniqueness_of :title, :scope => :wiki_id, :case_sensitive => false
  validates_associated :content
  
  def before_save
    self.title = Wiki.titleize(title)
  end
  
  def pretty_title
    WikiPage.pretty_title(title)
  end
  
  def content_for_version(version=nil)
    result = content.versions.find_by_version(version.to_i) if version
    result ||= content
    result
  end
  
  def diff(version_to=nil, version_from=nil)
    version_to = version_to ? version_to.to_i : self.content.version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to
    
    content_to = content.versions.find_by_version(version_to)
    content_from = content.versions.find_by_version(version_from)
    
    (content_to && content_from) ? WikiDiff.new(content_to, content_from) : nil
  end
  
  def self.pretty_title(str)
    (str && str.is_a?(String)) ? str.tr('_', ' ') : str
  end
  
  def project
    wiki.project
  end
end

class WikiDiff
  attr_reader :diff, :words, :content_to, :content_from
  
  def initialize(content_to, content_from)
    @content_to = content_to
    @content_from = content_from
    @words = content_to.text.split(/(\s+)/)
    @words = @words.select {|word| word != ' '}
    words_from = content_from.text.split(/(\s+)/)
    words_from = words_from.select {|word| word != ' '}    
    @diff = words_from.diff @words
  end
end
