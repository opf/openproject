#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::TextFormatting
  module Filters
    class AttachmentFilter < HTML::Pipeline::Filter
      include OpenProject::StaticRouting::UrlHelpers
      include OpenProject::ObjectLinking

      def matched_filenames_regex
        /(bmp|gif|jpe?g|png|svg)\z/
      end

      def call
        attachments = get_attachments

        rewriter = ::OpenProject::TextFormatting::Helpers::LinkRewriter.new context

        doc.css("img[src]").each do |node|
          # Check for relative URLs and replace them if needed
          if rewriter.applicable? node["src"]
            node["src"] = rewriter.replace node["src"]
            next
          end

          # Don't try to lookup attachments if we don't have any
          next if attachments.nil?

          # We allow linking to filenames that are replaced with their attachment URL
          lookup_attachment_by_name node, attachments
        end

        doc
      end

      ##
      # Lookup a local attachment name
      def lookup_attachment_by_name(node, attachments)
        filename = node["src"].downcase

        # We only match a specific set of attributes as before
        return unless filename&.match?(matched_filenames_regex)

        # Try to find the attachment
        if (attachment = attachments.detect { |att| att.filename.downcase == filename })
          node["src"] = url_to_attachment(attachment, only_path: context[:only_path])

          # Replace alt text with description, unless it has one already
          node["alt"] = node["alt"].presence || attachment.description
        end
      end

      def get_attachments
        attachments = context[:attachments] || context[:object].try(:attachments)

        return nil unless attachments

        attachments.sort_by(&:created_at).reverse
      end
    end
  end
end
