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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.shared_context "enumeration#active handling" do |default_supported| # rubocop:disable RSpec/ContextWording
  let(:enumeration) do
    super()
  rescue NoMethodError
    raise "'enumeration' let needs to be set"
  end

  describe "#active" do
    if default_supported
      context "with the enumeration being inactive and default before saving" do
        it "sets the enumeration to be active", :aggregate_failures do
          enumeration.active = false
          enumeration.is_default = true

          enumeration.save

          expect(enumeration).to be_persisted
          expect(enumeration.active).to be true
        end
      end

      context "with the enumeration being inactive and not default before saving" do
        it "keeps the value of active", :aggregate_failures do
          enumeration.active = false
          enumeration.is_default = false

          enumeration.save

          expect(enumeration).to be_persisted
          expect(enumeration.active).to be false
          expect(enumeration.is_default).to be false
        end
      end
    end
  end
end
