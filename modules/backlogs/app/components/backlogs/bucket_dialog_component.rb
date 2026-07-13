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

module Backlogs
  class BucketDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include Primer::FetchOrFallbackHelper

    DIALOG_ID = "bucket-dialog"
    FORM_ID = "bucket-dialog-form"
    FOOTER_ID = "bucket-dialog-footer"

    STATE_DEFAULT = :create
    STATE_OPTIONS = [STATE_DEFAULT, :edit].freeze

    attr_reader :backlog_bucket, :state

    delegate :create?, :edit?, to: :state

    def initialize(backlog_bucket:, state: STATE_DEFAULT)
      super

      @backlog_bucket = backlog_bucket
      @state = ActiveSupport::StringInquirer.new(fetch_or_fallback(STATE_OPTIONS, state, STATE_DEFAULT).to_s)
    end

    private

    def title
      create? ? t(:label_backlog_bucket_new) : t(:label_backlog_bucket_edit)
    end

    def button_caption
      create? ? t(:button_create) : t(:button_save)
    end
  end
end
