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

require_relative "../../lib_static/open_project/llm/features"

# Features that send requests to the configured LLM server.
#
# Add a feature here (or from a module engine initializer) so that
# administrators can assign it a model on the "AI models" page.

# The description assistant rewrites work package text on explicit user action.
# Plain chat completions only: no tools, no JSON mode, no streaming. Individual
# actions may override the model, which is why it is overridable.
OpenProject::Llm::Features.register :description_assistant,
                                    kind: :chat,
                                    prefers: %i[structured_output],
                                    overridable: true

# Semantic search embeds work packages into a pgvector index. Pinned because the
# stored vectors are meaningless under a different model: changing it is a
# destructive re-index rather than a swap.
OpenProject::Llm::Features.register :semantic_search,
                                    kind: :embedding,
                                    requires: %i[embeddings],
                                    pinned: true
