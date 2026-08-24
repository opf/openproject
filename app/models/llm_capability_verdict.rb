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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# What we know about one capability of one model on one server.
#
# Three states rather than a boolean, because the honest answer is very often
# "we cannot tell": the OpenAI model list carries no capability information at
# all, and only some servers offer a non-standard endpoint that does.
#
# The rule the rest of the system depends on: only :unsupported blocks. An
# :unknown verdict warns and lets the administrator proceed, because refusing
# on "we could not tell" would make most self-hosted servers unusable.
class LlmCapabilityVerdict < ApplicationRecord
  belongs_to :llm_connection

  enum :state, { supported: "supported", unsupported: "unsupported", unknown: "unknown" }, validate: true

  # Where the verdict came from. Orthogonal to the state, so that an
  # administrator's assertion can be shown as such without adding a fourth state
  # that every caller would have to handle.
  enum :source,
       { metadata: "metadata", probe: "probe", admin: "admin", observed: "observed" },
       prefix: true,
       validate: true

  validates :model_id, presence: true
  validates :capability, presence: true, uniqueness: { scope: %i[llm_connection_id model_id] }

  scope :for_model, ->(model_id) { where(model_id:) }
  scope :for_capability, ->(capability) { where(capability: capability.to_s) }

  # An administrator's assertion survives re-detection: they know something about
  # their deployment that we could not determine.
  scope :sticky, -> { where(source: "admin") }

  def blocking?
    unsupported?
  end

  def dimensions
    detail["dimensions"]
  end
end
