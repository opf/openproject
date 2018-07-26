#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module OpenProject::TextFormatting
  module Filters
    class AttachmentFilter < HTML::Pipeline::Filter
      include OpenProject::StaticRouting::UrlHelpers

      def matched_filenames_regex
        /(bmp|gif|jpe?g|png|svg)\z/
      end

      def call
        attachments = get_attachments
        return doc if attachments.nil?

        doc.css('img[src]').each do |node|
          # We allow linking to filenames that are replaced with their attachment URL
          filename = node['src'].downcase

          # We only match a specific set of attributes as before
          next unless filename =~ matched_filenames_regex

          # Try to find the attachment
          if found = attachments.detect { |att| att.filename.downcase == filename }
            node['src'] = url_for only_path: context[:only_path],
                                  controller: '/attachments',
                                  action: 'download',
                                  id: found

            # Replace alt text with description, unless it has one already
            node['alt'] = node['alt'].presence || found.description
          end
        end

        doc
      end

      def get_attachments
        attachments = context[:attachments] || context[:object].try(:attachments)
        if attachments
          attachments.sort_by(&:created_at).reverse
        end
      end
    end
  end
end
