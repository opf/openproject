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
  let(:variant) { create(:type_variant, type:) }
  let(:aspect) { TypeVariant::PDF_EXPORT }

  subject(:service) { described_class.new(variant:, aspect:) }

  describe "#call" do
    it "links the aspect to the variant's base" do
      expect(variant).not_to be_linked(aspect)

      result = service.call

      expect(result).to be_success
      expect(variant.reload).to be_linked(aspect)
      expect(variant.source_for(aspect)).to eq(type.default_variant)
    end

    it "is idempotent when the aspect is already linked" do
      service.call

      result = service.call

      expect(result).to be_success
      expect(variant.reload).to be_linked(aspect)
    end

    context "when the variant is the base" do
      let(:variant) { type.default_variant }

      it "fails because a base cannot inherit" do
        result = service.call

        expect(result).not_to be_success
        expect(variant.reload).not_to be_linked(aspect)
      end
    end
  end
end
