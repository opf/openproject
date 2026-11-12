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

RSpec.describe Redmine::Acts::Customizable, "validation skipping" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      include Redmine::Acts::Customizable

      # Just setting it to some existing table to avoid problems
      self.table_name = "users"
      def self.name = "CustomizableModelForSpec"
    end
  end

  describe ".acts_as_customizable" do
    # rubocop:disable RSpec/MessageSpies
    context "with :validate_on option" do
      it "calls the validation with on: option" do
        expect(klass).to receive(:validate).with(:validate_custom_values, on: :update)
        klass.acts_as_customizable validate_on: :update
      end
    end

    context "with :validate_except_on option" do
      it "calls the validation with except: option" do
        expect(klass).to receive(:validate).with(:validate_custom_values, except_on: :create)
        klass.acts_as_customizable validate_except_on: :create
      end
    end

    context "with :validate_if option" do
      it "calls the validation with if: option" do
        condition = ->(model) { model.some_condition? }
        expect(klass).to receive(:validate).with(:validate_custom_values, if: condition)
        klass.acts_as_customizable validate_if: condition
      end
    end

    context "with :validate_unless option" do
      it "calls the validation with unless: option" do
        condition = ->(model) { model.some_condition? }
        expect(klass).to receive(:validate).with(:validate_custom_values, unless: condition)
        klass.acts_as_customizable validate_unless: condition
      end
    end
    # rubocop:enable RSpec/MessageSpies
  end
end
