# frozen_string_literal: true

module Bim
  # Dimension table for users (Type 2 Slowly Changing Dimension)
  # Tracks historical changes to user attributes for workforce analytics
  class DimUser < ApplicationRecord
    self.table_name = 'bim_dim_users'

    # Associations
    belongs_to :user
    has_many :portfolio_metrics, class_name: 'Bim::PortfolioMetric', foreign_key: :dim_user_id

    # Validations
    validates :user_id, presence: true
    validates :user_name, presence: true
    validates :valid_from, presence: true

    # Scopes
    scope :current, -> { where(is_current: true) }
    scope :by_role, ->(role) { where(user_role: role) }
    scope :by_department, ->(dept) { where(department: dept) }
    scope :by_discipline, ->(disc) { where(discipline: disc) }

    # Class methods
    class << self
      # Get or create current dimension record for a user
      def for_user(user, as_of: Time.current)
        dim_record = where(user_id: user.id, is_current: true).first

        if dim_record
          # Check if user attributes have changed
          if attributes_changed?(dim_record, user)
            dim_record.update!(valid_to: as_of, is_current: false)
            dim_record = create_from_user(user, as_of)
          end
        else
          dim_record = create_from_user(user, as_of)
        end

        dim_record
      end

      # Create dimension record from user
      def create_from_user(user, valid_from = Time.current)
        create!(
          user: user,
          user_name: "#{user.firstname} #{user.lastname}".strip,
          user_login: user.login,
          user_email: user.mail,
          user_role: determine_user_role(user),
          department: user.custom_field_value('department'),
          discipline: user.custom_field_value('discipline'),
          valid_from: valid_from,
          valid_to: '9999-12-31',
          is_current: true
        )
      end

      # Check if tracked attributes have changed
      def attributes_changed?(dim_record, user)
        dim_record.user_name != "#{user.firstname} #{user.lastname}".strip ||
          dim_record.user_role != determine_user_role(user) ||
          dim_record.department != user.custom_field_value('department') ||
          dim_record.discipline != user.custom_field_value('discipline')
      end

      # Determine user's primary role
      def determine_user_role(user)
        return 'admin' if user.admin?

        # Check global roles
        global_role = user.global_roles.first&.name&.downcase
        return global_role if global_role.present?

        # Check most common project role
        project_roles = user.members.map { |m| m.roles.first&.name }.compact
        most_common_role = project_roles.group_by(&:itself).max_by { |_, v| v.size }&.first

        most_common_role&.downcase || 'member'
      end
    end

    # Instance methods

    # Get snapshot of this dimension at a specific point in time
    def self.as_of(date)
      where('valid_from <= ? AND valid_to > ?', date, date)
    end

    # Close this dimension record
    def close!(closing_date = Time.current)
      update!(valid_to: closing_date, is_current: false)
    end

    # Display name
    def display_name
      "#{user_name} (#{user_role&.capitalize})"
    end
  end
end
