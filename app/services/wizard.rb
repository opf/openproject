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

class Wizard
  StepDefinition = Data.define(:name, :section, :if, :completed_if, :preparation) do
    def use_on?(wizard)
      call_with_model(self.if, wizard)
    end

    def completed_on?(wizard)
      call_with_model(completed_if, wizard)
    end

    def prepare_on(wizard)
      call_with_model(preparation, wizard)
    end

    private

    def call_with_model(sym_or_callable, wizard)
      if sym_or_callable.is_a? Symbol
        wizard.send(sym_or_callable, wizard.model)
      else
        sym_or_callable.call(wizard.model)
      end
    end
  end

  class << self
    def steps_by_name
      @steps_by_name ||= {}
    end

    def steps
      steps_by_name.values
    end

    def step(name, completed_if:, if: ->(_) { true }, preparation: ->(_) {}, section: name)
      name = name.to_sym
      steps_by_name[name] = StepDefinition.new(name:, section:, if:, completed_if:, preparation:)
    end
  end

  attr_reader :model, :user

  def initialize(model:, user: nil)
    @model = model
    @user = user
  end

  # Determines the next step, given a current step in the wizard
  def step_after(current_step)
    current_step_idx = steps.find_index { |s| s == current_step }
    return nil if current_step_idx.nil?

    steps[current_step_idx + 1]
  end

  # Determines the next step given the model state and the `completed_if` conditions that are defined on the wizard
  def foresee_next_step
    pending_steps.first
  end

  def prepare_next_step
    next_step = foresee_next_step
    return nil if next_step.nil?

    steps_by_name.fetch(next_step).prepare_on(self)

    next_step
  end

  def section_name(name)
    steps_by_name.fetch(name).section
  end

  def steps
    self.class.steps.select { |s| s.use_on?(self) }.map(&:name)
  end

  def completed_steps
    steps.select { |name| steps_by_name.fetch(name).completed_on?(self) }
  end

  def pending_steps
    steps.reject { |name| steps_by_name.fetch(name).completed_on?(self) }
  end

  private

  def steps_by_name
    self.class.steps_by_name
  end
end
