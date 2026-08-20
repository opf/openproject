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

RSpec.describe WorkPackageTypes::IndependentMode do
  describe ".available_for" do
    it "offers copy and default for form configuration" do
      expect(described_class.available_for(TypeVariant::FORM_CONFIGURATION))
        .to eq([described_class::COPY, described_class::DEFAULT])
    end

    it "offers copy and empty for patterns" do
      expect(described_class.available_for(TypeVariant::DEFAULTS))
        .to eq([described_class::COPY, described_class::EMPTY])
    end

    it "offers copy and default for PDF export" do
      expect(described_class.available_for(TypeVariant::PDF_EXPORT))
        .to eq([described_class::COPY, described_class::DEFAULT])
    end

    it "offers copy and empty for workflows" do
      expect(described_class.available_for(TypeVariant::WORKFLOWS))
        .to eq([described_class::COPY, described_class::EMPTY])
    end

    it "offers copy and empty for project attributes" do
      expect(described_class.available_for(TypeVariant::PROJECT_ATTRIBUTES))
        .to eq([described_class::COPY, described_class::EMPTY])
    end

    it "returns no modes for an aspect without a switch flow" do
      expect(described_class.available_for("unknown_aspect")).to eq([])
    end
  end

  describe ".available?" do
    it "is true for a mode the aspect offers" do
      expect(described_class).to be_available(TypeVariant::FORM_CONFIGURATION, described_class::DEFAULT)
    end

    it "is false for a mode the aspect does not offer" do
      expect(described_class).not_to be_available(TypeVariant::FORM_CONFIGURATION, described_class::EMPTY)
      expect(described_class).not_to be_available(TypeVariant::DEFAULTS, described_class::DEFAULT)
    end
  end
end
