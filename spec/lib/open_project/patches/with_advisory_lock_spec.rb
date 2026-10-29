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

RSpec.describe OpenProject::Patches::WithAdvisoryLock do
  before do
    allow(OpenProject::Mutex).to receive(:advisory_lock_name) { |name| "#{name}_ns" }
  end

  it "applies the lock name hook to with_advisory_lock" do
    held = WorkPackage.with_advisory_lock("foo") { WorkPackage.current_advisory_lock }

    expect(held).to eq("foo_ns")
  end

  it "applies the lock name hook to with_advisory_lock!" do
    held = WorkPackage.with_advisory_lock!("foo") { WorkPackage.current_advisory_lock }

    expect(held).to eq("foo_ns")
  end

  it "applies the lock name hook to advisory_lock_exists?" do
    WorkPackage.with_advisory_lock("foo") do
      expect(WorkPackage.advisory_lock_exists?("foo")).to be(true)
      expect(WorkPackage.advisory_lock_exists?("foo_ns")).to be(false)
    end
  end

  it "applies the lock name hook to OpenProject::Mutex only once" do
    held = OpenProject::Mutex.with_advisory_lock(WorkPackage, "foo") { WorkPackage.current_advisory_lock }

    expect(held).to eq("foo_ns")
  end

  [WorkPackage, CustomField::Hierarchy::Item].each do |model|
    it "applies the lock name hook to the closure_tree lock of #{model}" do
      held = model._ct.with_advisory_lock { model.current_advisory_lock }

      expect(held).to eq("#{model._ct.advisory_lock_name}_ns")
    end
  end
end
