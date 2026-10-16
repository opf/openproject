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

module Llm
  # Turns a schema-constrained answer into a Hash, or fails loudly.
  #
  # RubyLLM's Chat#with_schema fails soft: when the answer does not parse as
  # JSON it rescues and leaves the content as a String, so a caller expecting a
  # Hash gets a String and only notices further downstream.
  #
  # That matters most on a self-hosted server, which is exactly where the
  # structured_output capability verdict is :unknown rather than :supported, and
  # so exactly where the model is most likely to answer in prose.
  module StructuredOutput
    module_function

    # @param message [RubyLLM::Message] the answer from Chat#ask
    # @raise [Llm::Errors::ParseError] when the model did not honour the schema
    # @return [Hash]
    def parse!(message)
      content = message.respond_to?(:content) ? message.content : message

      return content.deep_symbolize_keys if content.is_a?(Hash)

      raise Llm::Errors::ParseError, "Model did not answer with the requested structure"
    end
  end
end
