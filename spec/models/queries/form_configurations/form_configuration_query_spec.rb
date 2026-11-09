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

RSpec.describe Queries::FormConfigurations::FormConfigurationQuery do
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:phase) { create(:type, name: "Phase") }

  shared_let(:on_bug) { create(:project, name: "OnBug", types: [bug]) }
  shared_let(:on_task) { create(:project, name: "OnTask", types: [task]) }
  shared_let(:on_phase) { create(:project, name: "OnPhase", types: [phase]) }

  shared_let(:shared_form) { bug.default_variant.form_configuration }
  shared_let(:phase_form) { phase.default_variant.form_configuration }

  before_all do
    orphaned = task.default_variant.form_configuration
    task.default_variant.update!(form_configuration: shared_form)
    orphaned.reload.destroy!

    shared_form.update!(name: "Standard form", description: "Shared across the board")
    phase_form.update!(name: "Phase only")
  end

  def results(&) = described_class.new.tap(&).results.to_a

  it "holds every form, ordered by name" do
    expect(results { it }.map(&:name)).to eq(["Phase only", "Standard form"])
  end

  it "finds a form by its name or description" do
    expect(results { it.where(:name, "~", ["STANDARD"]) }).to contain_exactly(shared_form)
    expect(results { it.where(:name, "~", ["across the"]) }).to contain_exactly(shared_form)
    expect(results { it.where(:name, "!~", ["standard"]) }).to contain_exactly(phase_form)
  end

  it "finds a shared form by any of the types using it" do
    expect(results { it.where(:type_id, "=", [task.id.to_s]) }).to contain_exactly(shared_form)
    expect(results { it.where(:type_id, "!", [bug.id.to_s]) }).to contain_exactly(phase_form)
  end

  it "finds a form by the projects its types are active in" do
    expect(results { it.where(:project_id, "=", [on_task.id.to_s]) }).to contain_exactly(shared_form)
    expect(results { it.where(:project_id, "!", [on_bug.id.to_s]) }).to contain_exactly(phase_form)
  end
end
