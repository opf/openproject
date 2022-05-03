#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

RSpec.shared_context "with storages module enabled" do
  let(:storages_module_active) { true }

  before do
    allow(OpenProject::FeatureDecisions).to receive(:storages_module_active?).and_return(storages_module_active)
  end
end

RSpec.shared_context "with storages module disabled" do
  let(:storages_module_active) { false }
end

RSpec.configure do |rspec|
  # examples tagged with `:enable_storages` will automatically have context
  # included and storages module enabled
  rspec.include_context "with storages module enabled", :enable_storages
  # examples tagged with `disable_storages` will automatically have context
  # included and storages module disabled
  rspec.include_context "with storages module disabled", :disable_storages
end
