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

module Redmine
  module Themes
  
    # Return an array of installed themes
    def self.themes
      @@installed_themes ||= scan_themes
    end
    
    # Rescan themes directory
    def self.rescan
      @@installed_themes = scan_themes
    end
    
    # Return theme for given id, or nil if it's not found
    def self.theme(id)
      themes.find {|t| t.id == id}
    end
  
    # Class used to represent a theme
    class Theme
      attr_reader :name, :dir, :stylesheets
      
      def initialize(path)
        @dir = File.basename(path)
        @name = @dir.humanize
        @stylesheets = Dir.glob("#{path}/stylesheets/*.css").collect {|f| File.basename(f).gsub(/\.css$/, '')}
      end
      
      # Directory name used as the theme id
      def id; dir end

      def <=>(theme)
        name <=> theme.name
      end
    end
    
    private
        
    def self.scan_themes
      dirs = Dir.glob("#{RAILS_ROOT}/public/themes/*").select do |f|
        # A theme should at least override application.css
        File.directory?(f) && File.exist?("#{f}/stylesheets/application.css")
      end
      dirs.collect {|dir| Theme.new(dir)}.sort
    end
  end
end

module ApplicationHelper
  def stylesheet_path(source)
    @current_theme ||= Redmine::Themes.theme(Setting.ui_theme)
    super((@current_theme && @current_theme.stylesheets.include?(source)) ?
      "/themes/#{@current_theme.dir}/stylesheets/#{source}" : source)
  end
  
  def path_to_stylesheet(source)
    stylesheet_path source
  end
end
