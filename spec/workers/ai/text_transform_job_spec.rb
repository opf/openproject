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

RSpec.describe AI::TextTransformJob do
  it "uses the dedicated queue" do
    expect(described_class.new.queue_name).to eq("ai_text_transforms")
  end

  it "is a no-op for an unknown run" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end

  it "is a no-op for a run that is no longer queued" do
    run = create(:ai_text_transform_run, :succeeded)
    allow(AI::TextTransforms::Execution).to receive(:new)

    described_class.perform_now(run.id)

    expect(AI::TextTransforms::Execution).not_to have_received(:new)
  end

  it "executes a queued run as its user" do
    run = create(:ai_text_transform_run)
    execution = instance_double(AI::TextTransforms::Execution)
    seen_user = nil
    allow(AI::TextTransforms::Execution).to receive(:new).with(run).and_return(execution)
    allow(execution).to receive(:call) { seen_user = User.current }

    described_class.perform_now(run.id)

    expect(seen_user).to eq(run.user)
  end
end
