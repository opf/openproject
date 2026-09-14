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

# Lets an LlmConnection's custom headers reach every request RubyLLM makes.
#
# An OpenAI-compatible deployment is routinely fronted by a gateway that
# authenticates on its own terms -- APISIX's key-auth wants an +apikey+ header,
# not +Authorization+ -- so an administrator must be able to add, and override,
# whatever the provider would send.
#
# RubyLLM's public API cannot express that:
#
# * Chat#with_headers reaches chat only. Provider#embed takes no headers
#   argument at all, so an embedding request could never carry them.
# * Even for chat it merges the wrong way round -- +additional_headers.merge(
#   req.headers)+ -- so the provider's own headers win every collision and an
#   administrator can never replace Authorization.
#
# Provider#headers is the one hook that reaches chat, embeddings and model
# listing alike, and merging our values last makes an override actually override.
#
# The module is prepended onto each registered provider class rather than onto
# RubyLLM::Provider, because all thirteen providers define #headers themselves
# without calling super -- a patch on the base class would never be reached.
# Azure inherits OpenAI, so it receives the module twice; the inner copy is
# simply never consulted.
module OpenProject
  module Patches
    module RubyLLMProviderHeaders
      def headers
        custom = config.openproject_custom_headers

        return super if custom.blank?

        super.merge(custom.stringify_keys)
      end
    end
  end
end

OpenProject::Patches.patch_gem_version("ruby_llm", "1.16.0") do
  RubyLLM::Configuration.register_provider_options(%i[openproject_custom_headers])

  RubyLLM::Provider.providers.each_value do |provider_class|
    provider_class.prepend(OpenProject::Patches::RubyLLMProviderHeaders)
  end
end
