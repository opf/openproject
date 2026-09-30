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

RSpec.describe DeprecatedAlias do
  let(:clazz) do
    Class.new do
      extend DeprecatedAlias

      def secret_key
        "happiness"
      end
      deprecated_alias :special_key, :secret_key
    end
  end
  let(:deprecation_warning) do
    <<~MSG
      special_key is deprecated and will be removed in a future OpenProject version.

      Please use secret_key instead.

    MSG
  end
  let(:deprecation_instance) do
    instance_double(ActiveSupport::Deprecation, warn: nil)
  end

  subject(:object) { clazz.new }

  before do
    allow(ActiveSupport::Deprecation)
      .to receive(:new)
         .and_return(deprecation_instance)
  end

  it "aliases the method" do
    expect(object.special_key).to eq("happiness")

    expect(deprecation_instance)
      .to have_received(:warn)
            .with(deprecation_warning, an_instance_of(Array))
  end
end
