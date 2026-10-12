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
require_relative "../shared_expectations"

RSpec.describe Automations::Actions::Description do
  let(:key) { :description }
  let(:type) { :text_property }
  let(:value) { "First line\n\nSecond paragraph" }

  it_behaves_like "base custom action" do
    describe "#apply" do
      let(:work_package) { build_stubbed(:work_package) }

      it "sets the description to the action's value" do
        instance.values = ["First line\n\nSecond paragraph"]

        instance.apply(work_package)

        expect(work_package.description)
          .to eql "First line\n\nSecond paragraph"
      end

      it "clears the description without a value" do
        instance.values = []

        instance.apply(work_package)

        expect(work_package.description)
          .to be_nil
      end
    end

    describe "#required?" do
      it "is false" do
        expect(instance)
          .not_to be_required
      end
    end
  end
end
