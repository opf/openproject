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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

##
# Extracts sections of a BCF markup file
# manually. If we want to extract the entire markup,
# this should be turned into a representable/xml decorator

module OpenProject::Bim::BcfXml
  class MarkupExtractor
    attr_reader :entry
    attr_accessor :markup, :doc

    def initialize(entry)
      @markup = entry.get_input_stream.read
      @doc = Nokogiri::XML markup, nil, "UTF-8"
    end

    def uuid
      extract :@Guid, attribute: true
    end

    def title
      extract :Title
    end

    def priority
      extract :Priority
    end

    def status
      extract :@TopicStatus, attribute: true
    end

    def type
      extract :@TopicType, attribute: true
    end

    def description
      extract :Description
    end

    def author
      extract :CreationAuthor
    end

    def assignee
      extract :AssignedTo
    end

    def modified_author
      extract :ModifiedAuthor
    end

    def creation_date
      extract_date_time "/Markup/Topic/CreationDate"
    end

    def modified_date
      extract_date_time "/Markup/Topic/ModifiedDate"
    end

    def due_date
      extract_date_time "/Markup/Topic/DueDate"
    rescue ArgumentError
      nil
    end

    def viewpoints
      doc.xpath("/Markup/Viewpoints").map do |node|
        {
          uuid: node["Guid"],
          viewpoint: extract_from_node("Viewpoint", node),
          snapshot: extract_from_node("Snapshot", node)
        }.with_indifferent_access
      end
    end

    def comments
      doc.xpath("/Markup/Comment").map do |node|
        {
          uuid: node["Guid"],
          date: extract_date_time("Date", node),
          author: extract_from_node("Author", node),
          comment: extract_from_node("Comment", node),
          viewpoint_uuid: comment_viewpoint_uuid(node),
          modified_date: extract_date_time("ModifiedDate", node),
          modified_author: extract_from_node("ModifiedAuthor", node)
        }.with_indifferent_access
      end
    end

    def mail_addresses
      people
        .filter do |person|
          # person value is an email address
          person =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        end
        .uniq
    end

    def people
      ([assignee, author] + comments.pluck(:author)).filter(&:present?).uniq
    end

    private

    def comment_viewpoint_uuid(node)
      viewpoint_node = node.at("Viewpoint")
      extract_from_node("@Guid", viewpoint_node, attribute: true) if viewpoint_node
    end

    def extract_date_time(path, node = nil)
      node ||= doc
      date_time = extract_from_node(path, node)
      Time.iso8601(date_time) unless date_time.nil?
    end

    def extract(path, prefix: "/Markup/Topic/".freeze, attribute: false)
      path = [prefix, path.to_s].join("")
      extract_from_node(path, doc, attribute:)
    end

    def extract_from_node(path, node, attribute: false)
      suffix = attribute ? "" : "/text()".freeze
      path = [path.to_s, suffix].join("")
      node.xpath(path).to_s.presence
    end
  end
end
