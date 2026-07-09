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

require "spec_helper"

RSpec.describe Type::ConfigurationLinkable do
  let(:type) { create(:type) }
  let(:source) { create(:type) }
  let(:aspect) { Type::ConfigurationLink::SUBJECT }

  describe "#linked? and #source_for" do
    it "reports Independent (no link) by default" do
      expect(type).not_to be_linked(aspect)
      expect(type.source_for(aspect)).to be_nil
    end

    it "reports Linked once a link exists" do
      type.link!(aspect, source:)

      expect(type).to be_linked(aspect)
      expect(type.source_for(aspect)).to eq(source)
    end

    it "tracks each aspect independently" do
      type.link!(Type::ConfigurationLink::SUBJECT, source:)

      expect(type).to be_linked(Type::ConfigurationLink::SUBJECT)
      expect(type).not_to be_linked(Type::ConfigurationLink::PDF_EXPORT)
    end
  end

  describe "#link!" do
    it "re-points an existing link rather than creating a duplicate" do
      other_source = create(:type)
      type.link!(aspect, source:)

      expect { type.link!(aspect, source: other_source) }
        .not_to change { type.configuration_links.where(aspect:).count }.from(1)
      expect(type.source_for(aspect)).to eq(other_source)
    end
  end

  describe "#make_independent!" do
    it "removes the link for that aspect only" do
      type.link!(Type::ConfigurationLink::SUBJECT, source:)
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source:)

      type.make_independent!(Type::ConfigurationLink::SUBJECT)

      expect(type).not_to be_linked(Type::ConfigurationLink::SUBJECT)
      expect(type).to be_linked(Type::ConfigurationLink::PDF_EXPORT)
    end
  end

  describe "sub-type default seeding" do
    it "links both aspects to the parent when a sub-type is created" do
      parent = create(:type)
      child = create(:type, parent:)

      expect(child.source_for(Type::ConfigurationLink::PDF_EXPORT)).to eq(parent)
      expect(child.source_for(Type::ConfigurationLink::SUBJECT)).to eq(parent)
    end

    it "leaves a root type Independent for both aspects" do
      root = create(:type)

      expect(root).not_to be_linked(Type::ConfigurationLink::PDF_EXPORT)
      expect(root).not_to be_linked(Type::ConfigurationLink::SUBJECT)
    end
  end

  describe "deletion" do
    it "destroys the type's own links when the type is destroyed" do
      type.link!(aspect, source:)

      type.destroy

      expect(Type::ConfigurationLink.where(type_id: type.id)).to be_empty
    end

    it "prevents destroying a type that is still a source for another type" do
      type.link!(aspect, source:)

      expect(source.destroy).to be_falsey
      expect(source.errors[:base]).to be_present
    end
  end
end
