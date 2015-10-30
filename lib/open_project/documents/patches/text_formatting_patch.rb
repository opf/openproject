#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Documents::Patches
  module TextFormattingPatch
    def self.included(base)

      base.class_eval do

        def parse_redmine_links_with_documents(text, project, obj, attr, only_path, options)
          text.gsub!(/([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(document)((#+|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)/) do |_m|
            leading = $1
            esc = $2
            project_prefix = $3
            project_identifier = $4
            prefix = $5
            sep = $7 || $9
            identifier = $8 || $10
            link = nil
            if project_identifier
              project = Project.visible.find_by_identifier(project_identifier)
            end
            if esc.nil?
              if sep == '#'
                oid = identifier.to_i
                document = Document.visible.find_by_id(oid)
              elsif sep == ':' && project
                name = identifier.gsub(%r{^"(.*)"$}, "\\1")
                document = project.documents.visible.find_by_title(name)
              end
              if document
                link = link_to document.title, {
                  only_path: only_path,
                  controller: '/documents',
                  action: 'show', id: document },
                  class: 'document'
              end
            end
            leading + (link || "#{project_prefix}#{prefix}#{sep}#{identifier}")
          end

          parse_redmine_links_without_documents(text, project, obj, attr, only_path, options)
        end

        alias_method_chain :parse_redmine_links, :documents
      end

    end

  end
end

unless OpenProject::TextFormatting.included_modules.include?(OpenProject::Documents::Patches::TextFormattingPatch)
  OpenProject::TextFormatting.send(:include, OpenProject::Documents::Patches::TextFormattingPatch)
end
