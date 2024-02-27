#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class WikiPages::CopyService
  include ::Shared::ServiceContext
  include Contracted
  include ::Copy::Concerns::CopyAttachments

  attr_accessor :user,
                :model,
                :contract_class

  def initialize(user:, model:, contract_class: WikiPages::CreateContract)
    self.user = user
    self.model = model
    self.contract_class = contract_class
  end

  def call(send_notifications: nil, copy_attachments: true, **attributes)
    in_context(model, send_notifications:) do
      copy(attributes, copy_attachments)
    end
  end

  protected

  def copy(attribute_override, copy_attachments)
    attributes = copied_attributes(attribute_override)

    create(attributes)
      .on_success do |call|
      copy_wiki_page_attachments(call.result) if copy_attachments
    end
  end

  def create(attributes)
    WikiPages::CreateService
      .new(user:,
           contract_class:)
      .call(attributes.symbolize_keys)
  end

  # Copy the wiki page attributes together with the wiki page content attributes
  def copied_attributes(override)
    model
      .attributes
      .slice(*writable_attributes)
      .merge(override)
  end

  def writable_attributes
    instantiate_contract(model, user)
      .writable_attributes
  end

  def copy_wiki_page_attachments(copy)
    copy_attachments(
      'WikiPage',
      from: model,
      to: copy,
      references: %i[text]
    )
  end
end
