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

RSpec.describe WorkPackageTypes::FormConfiguration::LayoutLock,
               "concurrent moves",
               use_transactional_fixtures: false do
  self.use_transactional_tests = false

  before { fixture_connection_pool.unpin_connection! }

  after do
    FormConfiguration.where(id: form.id).find_each(&:destroy!)
  ensure
    fixture_connection_pool.pin_connection!(true)
  end

  let(:fixture_connection_pool) { ActiveRecord::Base.connection_pool }
  let!(:admin) { build_stubbed(:admin) }
  let!(:form) { create(:form_configuration) }
  let!(:details) { create(:form_configuration_group, form_configuration: form, label: "Details") }
  let!(:other) { create(:form_configuration_group, form_configuration: form, label: "Other") }
  let!(:priority) do
    create(:form_configuration_attribute, form_configuration: form, group: details, position: 1, attribute_key: "priority")
  end
  let!(:date) do
    create(:form_configuration_attribute, form_configuration: form, group: details, position: 2, attribute_key: "date")
  end

  def move_to_top_of_other(record)
    ActiveRecord::Base.connection_pool.with_connection do
      WorkPackageTypes::FormConfigurationRows::MoveService
        .new(user: admin, form_configuration: FormConfiguration.find(form.id), record:)
        .call(list_type: "attribute", list_id: other.id.to_s, prev_id: "")
    end
  end

  # rubocop:disable-next RSpec/ExampleLength
  it "makes the second writer wait until the first has committed", :aggregate_failures, retry: 0 do
    first_holds_lock = Concurrent::Event.new
    release_first = Concurrent::Event.new

    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
      .and_wrap_original do |original, entry, suffix = nil, *args, &block|
        result = original.call(entry, suffix, *args, &block)
        if Thread.current[:writer] == :first
          first_holds_lock.set
          release_first.wait(5)
        end
        result
      end

    first = Thread.new do
      Thread.current[:writer] = :first
      move_to_top_of_other(priority)
    end
    raise "first writer never took the lock" unless first_holds_lock.wait(5)

    second = Thread.new do
      Thread.current[:writer] = :second
      move_to_top_of_other(date)
    end
    sleep 0.5
    expect(second).to be_alive

    release_first.set
    results = [first, second].map { it.join(5)&.value }

    expect(results).to all(be_success)
    expect(other.members.reload.map(&:key)).to eq(%w[date priority])
    expect(other.members.map(&:position)).to eq([1, 2])
    expect(details.members.reload).to be_empty
  ensure
    release_first&.set
    [first, second].compact.each { it.join(5) || it.kill }
  end
end
