# frozen_string_literal: true

# -- copyright
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
# ++

require "sanitize"

module WorkPackages
  module ActivitiesTab
    module Journals
      class RevisionComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(changeset:, filter:)
          super

          @changeset = changeset
          @filter = filter
        end

        def render_committer_name(committer)
          render(Primer::Beta::Text.new(font_weight: :bold, mr: 1)) do
            remove_email_addresses(committer)
          end
        end

        def remove_email_addresses(committer)
          return "" if committer.blank?

          ERB::Util.html_escape(
            Sanitize.fragment(
              committer.gsub(%r{<[^>]+@[^>]+>}, ""),
              Sanitize::Config::RESTRICTED
            ).strip
          )
        end

        private

        attr_reader :changeset, :filter

        def render?
          filter != Filters::ONLY_COMMENTS
        end

        def user_name
          if changeset.user
            changeset.user.name
          else
            # Extract name from committer string (format: "name <email>")
            changeset.committer.split("<").first.strip
          end
        end

        def revision_url
          repository = changeset.repository

          show_revision_project_repository_path(project_id: repository.project_id, rev: changeset.revision)
        end

        def short_revision
          changeset.revision[0..7]
        end

        def copy_url_action_item(menu)
          menu.with_item(label: t("button_copy_link_to_clipboard"),
                         tag: :button,
                         content_arguments: {
                           data: {
                             action: "click->work-packages--activities-tab--item#copyActivityUrlToClipboard"
                           }
                         }) do |item|
            item.with_leading_visual_icon(icon: :copy)
          end
        end

        def render_user_name
          if changeset.user
            render_user_link(changeset.user)
          else
            render_committer_name(changeset.committer)
          end
        end

        def render_user_link(user)
          render(Primer::Beta::Link.new(
                   href: user_url(user),
                   target: "_blank",
                   scheme: :primary,
                   underline: false,
                   font_weight: :bold
                 )) do
            changeset.user.name
          end
        end
      end
    end
  end
end
