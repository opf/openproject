# frozen_string_literal: true

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

module Saml
  # Prepares SAML metadata XML for parsing by ruby-saml.
  #
  # Federation aggregates MAY contain thousands of individual entities.
  # Using ruby-saml directly would load the full document into REXML, which is extremely slow.
  # This class streams the XML and tries to extract the matching single EntityDescriptor when we can.
  class MetadataDocument
    class MetadataTooLargeError < StandardError; end

    class FederationMetadataError < StandardError; end

    MAX_SIZE = 150.megabytes

    def self.prepare(source, entity_id: nil)
      new(source, entity_id:).prepare
    end

    def initialize(source, entity_id: nil)
      @source = source
      @entity_id = entity_id.presence
    end

    def prepare
      if aggregate?
        read_entity_fragment!
      else
        read_all
      end
    end

    def read_entity_fragment!
      fragment = extract_entity_fragment
      if fragment.nil?
        message =
          if @entity_id
            "Entity '#{@entity_id}' not found in federation aggregate"
          else
            "No identity provider found in federation aggregate"
          end
        raise FederationMetadataError, message
      end

      fragment
    end

    # Decide whether the document is a federation aggregate by inspecting its root element.
    # Using +Nokogiri::XML::Reader+, we only advance to the root element and stop based on it.
    def aggregate?
      with_reader_io do |io|
        Nokogiri::XML::Reader(io).each do |node|
          next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT

          return node.local_name == "EntitiesDescriptor"
        end
      end

      false
    end

    private

    def extract_entity_fragment
      if @entity_id
        find_entity_by_id
      else
        find_first_idp_entity
      end
    end

    # We try to prevent calling outer_xml on all entities when looking.
    # Instead, we can only look at entityID attribute until the target is found,
    # and then call outer_xml only on that fragment.
    def find_entity_by_id
      with_reader_io do |io|
        Nokogiri::XML::Reader(io).each do |node|
          next unless entity_descriptor_element?(node)
          next unless node.attribute("entityID") == @entity_id

          return node.outer_xml
        end
      end

      nil
    end

    def find_first_idp_entity
      with_reader_io do |io|
        Nokogiri::XML::Reader(io).each do |node|
          next unless entity_descriptor_element?(node)

          fragment = node.outer_xml
          return fragment if idp_descriptor_fragment?(fragment)
        end
      end

      nil
    end

    def idp_descriptor_fragment?(fragment)
      Nokogiri::XML.fragment(fragment).at_xpath(".//*[local-name()='IDPSSODescriptor']").present?
    end

    def entity_descriptor_element?(node)
      node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT && node.local_name == "EntityDescriptor"
    end

    def read_all
      return @source if @source.is_a?(String)

      with_reader_io(&:read)
    end

    def with_reader_io(&)
      if @source.is_a?(String)
        StringIO.open(@source, &)
      else
        @source.rewind
        yield @source
      end
    end
  end
end
