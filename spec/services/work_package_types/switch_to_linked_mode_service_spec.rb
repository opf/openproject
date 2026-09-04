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

RSpec.describe WorkPackageTypes::SwitchToLinkedModeService do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:source) { create(:type).default_variant }
  let(:aspect) { TypeVariant::PDF_EXPORT }

  subject(:service) { described_class.new(variant:, aspect:) }

  describe "#call" do
    it "links the aspect to the chosen source" do
      result = service.call(source:)

      expect(result).to be_success
      expect(variant.source_for(aspect)).to eq(source)
    end

    it "re-points an existing link to a new source" do
      service.call(source:)
      other = create(:type).default_variant

      result = service.call(source: other)

      expect(result).to be_success
      expect(variant.reload.source_for(aspect)).to eq(other)
    end

    it "leaves the variant independent when no source is given" do
      result = service.call(source: nil)

      expect(result).to be_success
      expect(variant.reload).not_to be_linked(aspect)
    end

    it "fails when the source is the variant itself" do
      result = service.call(source: variant)

      expect(result).not_to be_success
      expect(variant.reload).not_to be_linked(aspect)
    end

    it "fails when linking would create a cycle" do
      link_configuration(source, source: variant, aspect:)

      result = service.call(source:)

      expect(result).not_to be_success
      expect(variant.reload).not_to be_linked(aspect)
    end
  end
end
