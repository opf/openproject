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

RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter do
  def property_names(representer)
    representer.representable_attrs.keys
  end

  def link_names(representer)
    representer.representable_attrs["links"].link_configs.map { |config, _block| config[:rel].to_s }
  end

  [API::V3::WorkPackages::WorkPackagePayloadRepresenter,
   API::V3::WorkPackages::WorkPackageAtTimestampRepresenter].each do |subclass|
    describe subclass.name do
      it "has all properties of the work package representer, including those added by modules" do
        expect(property_names(subclass)).to include(*property_names(described_class))
      end

      it "has all links of the work package representer, including those added by modules" do
        expect(link_names(subclass)).to include(*link_names(described_class))
      end
    end
  end
end
