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

require 'redmine/scm/adapters/abstract_adapter'
require 'rexml/document'

module Redmine
  module Scm
    module Adapters    
      class DarcsAdapter < AbstractAdapter      
        # Darcs executable name
        DARCS_BIN = "darcs"
        
        def initialize(url, root_url=nil, login=nil, password=nil)
          @url = url
          @root_url = url
        end

        def supports_cat?
          false
        end
              
        # Get info about the svn repository
        def info
          rev = revisions(nil,nil,nil,{:limit => 1})
          rev ? Info.new({:root_url => @url, :lastrev => rev.last}) : nil
        end
        
        # Returns the entry identified by path and revision identifier
        # or nil if entry doesn't exist in the repository
        def entry(path=nil, identifier=nil)
          e = entries(path, identifier)
          e ? e.first : nil
        end
        
        # Returns an Entries collection
        # or nil if the given path doesn't exist in the repository
        def entries(path=nil, identifier=nil)
          path_prefix = (path.blank? ? '' : "#{path}/")
          path = '.' if path.blank?
          entries = Entries.new          
          cmd = "#{DARCS_BIN} annotate --repodir #{@url} --xml-output"
          cmd << " --match \"hash #{identifier}\"" if identifier
          cmd << " #{path}"
          shellout(cmd) do |io|
            begin
              doc = REXML::Document.new(io)
              if doc.root.name == 'directory'
                doc.elements.each('directory/*') do |element|
                  next unless ['file', 'directory'].include? element.name
                  entries << entry_from_xml(element, path_prefix)
                end
              elsif doc.root.name == 'file'
                entries << entry_from_xml(doc.root, path_prefix)
              end
            rescue
            end
          end
          return nil if $? && $?.exitstatus != 0
          entries.sort_by_name
        end
    
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          path = '.' if path.blank?
          revisions = Revisions.new
          cmd = "#{DARCS_BIN} changes --repodir #{@url} --xml-output"
          cmd << " --from-match \"hash #{identifier_from}\"" if identifier_from
          cmd << " --last #{options[:limit].to_i}" if options[:limit]
          shellout(cmd) do |io|
            begin
              doc = REXML::Document.new(io)
              doc.elements.each("changelog/patch") do |patch|
                message = patch.elements['name'].text
                message << "\n" + patch.elements['comment'].text.gsub(/\*\*\*END OF DESCRIPTION\*\*\*.*\z/m, '') if patch.elements['comment']
                revisions << Revision.new({:identifier => nil,
                              :author => patch.attributes['author'],
                              :scmid => patch.attributes['hash'],
                              :time => Time.parse(patch.attributes['local_date']),
                              :message => message,
                              :paths => (options[:with_path] ? get_paths_for_patch(patch.attributes['hash']) : nil)
                            })
              end
            rescue
            end
          end
          return nil if $? && $?.exitstatus != 0
          revisions
        end
        
        def diff(path, identifier_from, identifier_to=nil, type="inline")
          path = '*' if path.blank?
          cmd = "#{DARCS_BIN} diff --repodir #{@url}"
          if identifier_to.nil?
            cmd << " --match \"hash #{identifier_from}\""
          else
            cmd << " --to-match \"hash #{identifier_from}\""
            cmd << " --from-match \"hash #{identifier_to}\""
          end
          cmd << " -u #{path}"
          diff = []
          shellout(cmd) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          return nil if $? && $?.exitstatus != 0
          DiffTableList.new diff, type    
        end
        
        private
                
        def entry_from_xml(element, path_prefix)
          Entry.new({:name => element.attributes['name'],
                     :path => path_prefix + element.attributes['name'],
                     :kind => element.name == 'file' ? 'file' : 'dir',
                     :size => nil,
                     :lastrev => Revision.new({
                       :identifier => nil,
                       :scmid => element.elements['modified'].elements['patch'].attributes['hash']
                       })
                     })        
        end
        
        # Retrieve changed paths for a single patch
        def get_paths_for_patch(hash)
          cmd = "#{DARCS_BIN} annotate --repodir #{@url} --summary --xml-output"
          cmd << " --match \"hash #{hash}\" "
          paths = []
          shellout(cmd) do |io|
            begin
              # Darcs xml output has multiple root elements in this case (tested with darcs 1.0.7)
              # A root element is added so that REXML doesn't raise an error
              doc = REXML::Document.new("<fake_root>" + io.read + "</fake_root>")
              doc.elements.each('fake_root/summary/*') do |modif|
                paths << {:action => modif.name[0,1].upcase,
                          :path => "/" + modif.text.chomp.gsub(/^\s*/, '')
                         }
              end
            rescue
            end
          end
          paths
        rescue CommandFailed
          paths
        end
      end
    end
  end
end
