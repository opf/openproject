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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenProject::Screens do
  describe ".assert_core_dependencies!" do
    it "does not raise when every core method is present" do
      expect { described_class.assert_core_dependencies! }.not_to raise_error
    end

    it "raises naming TypeVariant.all_work_package_form_attributes when it is missing" do
      allow(TypeVariant).to receive(:respond_to?).and_return(false)
      expect { described_class.assert_core_dependencies! }
        .to raise_error(/TypeVariant\.all_work_package_form_attributes/)
    end

    it "raises naming Project#type_variant when it is missing" do
      allow(Project).to receive(:method_defined?).and_return(false)
      expect { described_class.assert_core_dependencies! }.to raise_error(/Project#type_variant/)
    end
  end
end
