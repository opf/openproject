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

require 'model_contract'

module Attachments
  module ValidateReplacements
    extend ActiveSupport::Concern

    included do
      validate :validate_attachments_replacements
    end

    private

    def validate_attachments_replacements
      model.attachments_replacements&.each do |attachment|
        error_if_attachment_assigned(attachment)
        error_if_other_user_attachment(attachment)
      end
    end

    def error_if_attachment_assigned(attachment)
      errors.add :attachments, :unchangeable if attachment.container && attachment.container != model
    end

    def error_if_other_user_attachment(attachment)
      errors.add :attachments, :does_not_exist if !attachment.container && attachment.author != user
    end
  end
end
