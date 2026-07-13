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

RSpec.describe Journals::CreateService::Association do
  describe ".register" do
    around do |example|
      original = described_class.instance_variable_get(:@registry).dup
      example.run
    ensure
      described_class.instance_variable_set(:@registry, original)
    end

    it "adds a new name to the registry" do
      expect { described_class.register(:NewAssociation) }
        .to change { described_class.instance_variable_get(:@registry) }
        .to include(:NewAssociation)
    end

    it "is idempotent — duplicate registrations are ignored" do
      described_class.register(:NewAssociation)
      expect { described_class.register(:NewAssociation) }
        .not_to change { described_class.instance_variable_get(:@registry).size }
    end

    it "accepts strings and coerces them to symbols" do
      described_class.register("NewAssociation")
      expect(described_class.instance_variable_get(:@registry)).to include(:NewAssociation)
    end
  end

  describe ".for" do
    it "includes core associations for any journable" do
      journable = instance_double(WorkPackage, customizable?: true, respond_to?: false)
      allow(journable).to receive(:respond_to?).with(:attachable?).and_return(true)
      allow(journable).to receive(:respond_to?).with(:custom_comments).and_return(false)
      allow(journable).to receive(:respond_to?).with(:file_links).and_return(false)
      allow(journable).to receive(:respond_to?).with(:agenda_items).and_return(false)
      allow(journable).to receive(:respond_to?).with(:phases).and_return(false)

      associations = described_class.for(journable)
      expect(associations.map(&:class)).to include(Journals::CreateService::Attachable)
    end

    it "excludes associations whose #associated? returns false" do
      journable = instance_double(WorkPackage, customizable?: false, respond_to?: false)
      allow(journable).to receive(:respond_to?).and_return(false)

      associations = described_class.for(journable)
      expect(associations).to be_empty
    end
  end
end
