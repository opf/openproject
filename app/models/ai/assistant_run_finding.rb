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

module AI
  class AssistantRunFinding < ApplicationRecord
    include AI::Proposal

    belongs_to :run, class_name: "AI::AssistantRun", inverse_of: :findings

    enum :source, { rule: "rule", ai: "ai" }, validate: true
    enum :severity, { high: "high", medium: "medium", low: "low" }, validate: true
    enum :dismiss_reason, {
      wrong: "wrong",
      not_relevant: "not_relevant",
      already_known: "already_known"
    }, validate: { allow_nil: true }, prefix: :dismissed_as

    validates :area, :text, presence: true
    validates :evidence, presence: true

    scope :by_severity, -> { unscope(:order).in_order_of(:severity, severities.values).order(:id) }

    def proposal_work_package = run.work_package

    def proposal_user = run.user

    def proposal_changeable_attributes = run.skill.changeable_attributes

    def proposal_journal_cause = Journal::CausedByAssistantSkill.new(run:)

    def proposal_siblings = run.findings.open
  end
end
