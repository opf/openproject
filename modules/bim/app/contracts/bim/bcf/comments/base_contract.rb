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

module Bim::Bcf
  module Comments
    class BaseContract < BaseContract
      attribute :issue
      attribute :viewpoint
      attribute :reply_to

      validate :user_allowed_to_manage_bcf
      validate :validate_viewpoint_reference
      validate :validate_reply_to_comment

      private

      def user_allowed_to_manage_bcf
        errors.add :base, :error_unauthorized unless @user.allowed_in_project?(:manage_bcf, model.issue.work_package.project)
      end

      def validate_viewpoint_reference
        errors.add(:viewpoint, :does_not_exist) if model.viewpoint.is_a?(::Bim::Bcf::NonExistentViewpoint)
      end

      def validate_reply_to_comment
        errors.add(:bcf_comment, :does_not_exist) if model.reply_to.is_a?(::Bim::Bcf::NonExistentComment)
      end
    end
  end
end
