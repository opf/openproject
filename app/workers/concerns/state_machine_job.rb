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

# A StateMachineJob is a job that consists of multiple steps to complete where a step needs
# to be finished before the next step is to be taken. Between each step, an amount of time may have to pass.
# A job including this concern can define step-blocks that will be executed one after another.
# A step receives the return value of the previous step-block as input. In case a waiting time is specified
# the job will reschedule itself.
module StateMachineJob
  extend ActiveSupport::Concern

  included do
    def perform(state, *)
      results = instance_exec(*, &states[state][:block])

      to = states[state][:to]

      switch_state(to, *results) if to
    end

    class_attribute :states,
                    instance_writer: false,
                    default: {}

    # Defines a new step, that can then be executed either by starting at this step
    # (by providing the step name as the first parameter of a call to #perform), or as a step
    # in a chain of steps.
    # @param name<Symbol> The name of the step that serves as an identifier to subsequent calls.
    # @param to<Symbol, NilClass> The name of the step triggered after this step. If the value is *nil*, no subsequent
    #                             step will be triggered.
    # @param wait<Lambda> The result of the lambda dictates the amount of time the job waits before the next step is
    #                     executed
    # @param block<Proc> The code to execute as part of the step. The block will be executed in the context of the
    #                    job instance, not the class.
    def self.state(name, to: nil, wait: nil, &block)
      states[name] = { to:, wait:, block: }
    end

    private

    def switch_state(to, *results)
      wait = states[to][:wait]

      if wait
        self
          .class
          .set(wait: wait.call)
          .perform_later(to, *results)
      else
        perform(to, *results)
      end
    end
  end
end
