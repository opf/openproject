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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
class EnterpriseToken < ApplicationRecord
  EXPIRING_SOON_DAYS = 30

  class << self
    def all_tokens
      all.sort_by(&:sort_key)
    end

    def active_tokens
      RequestStore.fetch(:current_ee_tokens) do
        set_active_tokens
      end
    end

    def active_non_trial_tokens
      active_tokens.reject(&:trial?)
    end

    def active_trial_token
      active_tokens.find(&:trial?)
    end

    def table_exists?
      connection.data_source_exists? table_name
    end

    def allows_to?(feature)
      active_tokens.any? { |token| Authorization::EnterpriseService.new(token).call(feature).result }
    end

    def active?
      active_tokens.any?
    end

    def trial_only?
      active_non_trial_tokens.empty? && active_trial_token.present?
    end

    def available_features
      active_tokens.map(&:available_features).inject(Set.new, :|)
    end

    def non_trialling_features
      active_non_trial_tokens.map(&:available_features).inject(Set.new, :|)
    end

    def trialling_features
      available_features - non_trialling_features
    end

    def trialling?(feature)
      trialling_features.include?(feature)
    end

    def hide_banners?
      OpenProject::Configuration.ee_hide_banners?
    end

    def user_limit
      if active_non_trial_tokens.any?
        get_user_limit_of(active_non_trial_tokens)
      elsif active_trial_token
        get_user_limit_of([active_trial_token])
      end
    end

    def set_active_tokens
      # although we use the `active` scope here, we still need to filter out non-active tokens
      # as not all token validity period is extracted into the DB
      EnterpriseToken
        .active
        .order(Arel.sql("created_at DESC"))
        .to_a
        .select { it.active? && !it.invalid_domain? }
    end

    def clear_current_tokens_cache
      RequestStore.delete :current_ee_tokens
    end

    def get_user_limit_of(tokens)
      tokens.partition(&:unlimited_users?)
        .find(proc { [] }, &:present?)
        .map(&:max_active_users)
        .max
    end
  end

  FAR_FUTURE_DATE = Date.new(9999, 1, 1)
  private_constant :FAR_FUTURE_DATE

  validates :encoded_token, presence: true,
                            uniqueness: { message: I18n.t("activerecord.errors.models.enterprise_token.already_added") }
  validate :valid_token_object
  validate :valid_domain
  validate :one_trial_token

  before_validation :strip_encoded_token
  before_save :extract_validity_from_token
  before_save :clear_current_tokens_cache
  before_destroy :clear_current_tokens_cache

  scope :active, ->(date = Date.current) {
    where(<<~SQL.squish, date: date)
      (valid_from IS NULL OR valid_from <= :date)
      AND
      (valid_until IS NULL OR valid_until >= :date)
    SQL
  }

  delegate :will_expire?,
           :subscriber,
           :mail,
           :company,
           :domain,
           :issued_at,
           :starts_at,
           :expires_at,
           :reprieve_days,
           :reprieve_days_left,
           :restrictions,
           :available_features,
           :plan,
           :features,
           :version,
           :started?,
           :trial?,
           :active?,
           to: :token_object

  def token_object
    load_token! unless defined?(@token_object)
    @token_object
  end

  def allows_to?(action)
    Authorization::EnterpriseService.new(self).call(action).result
  end

  delegate :clear_current_tokens_cache, to: :EnterpriseToken

  def expiring_soon?
    token_object.will_expire? \
      && token_object.active?(reprieve: false) \
      && token_object.expires_at <= EXPIRING_SOON_DAYS.days.from_now
  end

  def in_grace_period?
    token_object.expired?(reprieve: false) \
      && !token_object.expired?(reprieve: true)
  end

  def expired?(reprieve: true)
    token_object.expired?(reprieve:)
  end

  def statuses
    statuses = []
    if trial?
      statuses << :trial
    end
    if invalid_domain?
      statuses << :invalid_domain
    end
    if !started?
      statuses << :not_active
    elsif expiring_soon?
      statuses << :expiring_soon
    elsif in_grace_period?
      statuses << :in_grace_period
    elsif expired?
      statuses << :expired
    end
    statuses
  end

  ##
  # The domain is only validated for tokens from version 2.0 onwards.
  def invalid_domain?
    return false unless token_object&.validate_domain?

    !token_object.valid_domain?(Setting.host_name)
  end

  def unlimited_users?
    max_active_users.nil?
  end

  def max_active_users
    Hash(restrictions)[:active_user_count]
  end

  def sort_key
    [expires_at || FAR_FUTURE_DATE, starts_at || FAR_FUTURE_DATE]
  end

  def days_left
    (expires_at.to_date - Time.zone.today).to_i
  end

  private

  def strip_encoded_token
    self.encoded_token = encoded_token.strip if encoded_token.present?
  end

  def load_token!
    @token_object = OpenProject::Token.import(encoded_token)
  rescue OpenProject::Token::ImportError => e
    Rails.logger.error "Failed to load EE token: #{e}"
    nil
  end

  def valid_token_object
    errors.add(:encoded_token, :unreadable) unless load_token!
  end

  def valid_domain
    errors.add :domain, :invalid if invalid_domain?
  end

  def one_trial_token
    if self.class.active_trial_token.present?
      errors.add :base, :only_one_trial
    end
  end

  def extract_validity_from_token
    return unless token_object

    self.valid_from = token_object.starts_at
    self.valid_until = if token_object.will_expire?
                         token_object.expires_at.next_day(token_object.reprieve_days.to_i)
                       end
  end
end
