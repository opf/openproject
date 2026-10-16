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
# Creates or updates a BCF issue and markup from a work package
module OpenProject::Bim::BcfXml
  class BaseWriter
    attr_reader :markup_doc

    def initialize
      @markup_doc = build_markup_document
    end

    protected

    def root_node
      raise SubclassResponsibilityError
    end

    def root_node_attributes
      {}
    end

    ##
    # Initial markup file as basic BCF compliant xml
    def build_markup_document
      Nokogiri::XML::Builder
        .new(encoding: "UTF-8") do |xml|
          xml.comment created_by_comment
          xml.send(root_node,
                   "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                   "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
                   **root_node_attributes)
        end
        .doc
    end

    def prepend_into_or_insert(parent_node, node)
      if first_child = parent_node.children.select(&:element?)&.first
        first_child.previous = node
      else
        node.parent = parent_node
      end
    end

    def fetch(parent_node, name)
      node = parent_node.at(name) || Nokogiri::XML::Node.new(name, markup_doc)
      node.parent = parent_node unless node.parent.present?
      node
    end

    ##
    #
    def created_by_comment
      " Created by #{Setting.app_title} #{OpenProject::VERSION} at #{Time.now} "
    end

    def to_bcf_datetime(date_time)
      date_time.utc.iso8601
    end

    def to_bcf_date(date)
      date.iso8601
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end
