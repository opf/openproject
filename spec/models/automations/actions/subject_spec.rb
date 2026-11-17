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

RSpec.describe Automations::Actions::Subject do
  let(:key) { :subject }
  let(:type) { :string_property }
  let(:value) { "A better subject" }

  it_behaves_like "base custom action" do
    describe "#apply" do
      let(:work_package) { build_stubbed(:work_package) }

      it "sets the subject to the action's value" do
        instance.values = ["A better subject"]

        instance.apply(work_package)

        expect(work_package.subject)
          .to eql "A better subject"
      end
    end

    describe "#required?" do
      it "is true" do
        expect(instance)
          .to be_required
      end
    end

    describe "#validate" do
      let(:errors) do
        build_stubbed(:automation).errors
      end

      it "is invalid without a value" do
        instance.values = []

        instance.validate(errors)

        expect(errors.symbols_for(:actions))
          .to include(:empty)
      end
    end
  end
end
