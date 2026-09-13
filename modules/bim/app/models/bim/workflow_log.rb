# frozen_string_literal: true

module Bim
  class WorkflowLog < ApplicationRecord
    self.table_name = 'bim_workflow_logs'

    # Associations
    belongs_to :workflow_template, class_name: 'Bim::WorkflowTemplate'
    belongs_to :workflowable, polymorphic: true
    belongs_to :user

    # Validations
    validates :to_state, presence: true
    validates :user, presence: true
    validates :workflowable, presence: true
    validates :workflow_template, presence: true

    # Scopes
    scope :for_workflowable, ->(workflowable) {
      where(workflowable_type: workflowable.class.name, workflowable_id: workflowable.id)
    }
    scope :for_template, ->(template_id) { where(workflow_template_id: template_id) }
    scope :by_user, ->(user_id) { where(user_id: user_id) }
    scope :recent, ->(days = 30) { where('created_at > ?', days.days.ago) }
    scope :transitions, -> { where.not(from_state: nil) }
    scope :initial_states, -> { where(from_state: nil) }
    scope :to_state, ->(state) { where(to_state: state) }
    scope :from_state, ->(state) { where(from_state: state) }
    scope :automated, -> { where(automated: true) }
    scope :manual, -> { where(automated: false) }
    scope :chronological, -> { order(created_at: :asc) }
    scope :reverse_chronological, -> { order(created_at: :desc) }

    # Get duration label (human-readable)
    def duration_label
      return nil unless duration_in_state

      seconds = duration_in_state
      if seconds < 60
        "#{seconds}s"
      elsif seconds < 3600
        "#{(seconds / 60).round}min"
      elsif seconds < 86400
        "#{(seconds / 3600.0).round(1)}h"
      else
        "#{(seconds / 86400.0).round(1)}d"
      end
    end

    # Get state transition label (e.g., "Draft → In Review")
    def transition_label
      template = workflow_template
      from_label = from_state ? template.state_label(from_state) : 'Initial'
      to_label = template.state_label(to_state)
      "#{from_label} → #{to_label}"
    end

    # Check if this is an initial state entry
    def initial_entry?
      from_state.nil?
    end

    # Check if transition moved to a final state
    def to_final_state?
      workflow_template.final_state?(to_state)
    end

    # Get transition metadata as formatted string
    def metadata_summary
      return nil if metadata.blank?

      metadata.map { |k, v| "#{k.humanize}: #{v}" }.join(', ')
    end

    # Get actor display name
    def actor_name
      user&.name || 'System'
    end

    # Create log entry with duration calculation
    def self.create_transition!(workflowable:, from_state:, to_state:, transition_name:, user:, comment: nil, metadata: {}, automated: false, request: nil)
      # Calculate duration in previous state
      last_log = for_workflowable(workflowable).reverse_chronological.first
      duration = if last_log && from_state.present?
                   (Time.current - last_log.created_at).to_i
                 else
                   nil
                 end

      create!(
        workflow_template: workflowable.workflow_template,
        workflowable: workflowable,
        from_state: from_state,
        to_state: to_state,
        transition_name: transition_name,
        user: user,
        comment: comment,
        metadata: metadata,
        duration_in_state: duration,
        automated: automated,
        ip_address: request&.remote_ip,
        user_agent: request&.user_agent
      )
    end

    # Get statistics for a workflowable
    def self.statistics_for(workflowable)
      logs = for_workflowable(workflowable).chronological

      {
        total_transitions: logs.count,
        total_duration: logs.sum(:duration_in_state) || 0,
        average_transition_time: logs.where.not(duration_in_state: nil).average(:duration_in_state)&.to_i,
        states_visited: logs.pluck(:to_state).uniq,
        contributors: logs.pluck(:user_id).uniq.count,
        automated_count: logs.automated.count,
        manual_count: logs.manual.count,
        created_at: workflowable.created_at,
        last_transition_at: logs.last&.created_at
      }
    end

    # Get state history timeline
    def self.timeline_for(workflowable)
      for_workflowable(workflowable).chronological.map do |log|
        {
          timestamp: log.created_at,
          from_state: log.from_state,
          to_state: log.to_state,
          transition: log.transition_name,
          user: log.actor_name,
          duration: log.duration_label,
          comment: log.comment,
          automated: log.automated
        }
      end
    end

    # Get state distribution across all logs
    def self.state_distribution
      group(:to_state).count
    end

    # Get average time spent in each state
    def self.average_durations_by_state
      group(:to_state)
        .where.not(duration_in_state: nil)
        .average(:duration_in_state)
        .transform_values(&:to_i)
    end

    # Get user activity summary
    def self.user_activity
      group(:user_id)
        .select('user_id, COUNT(*) as transition_count, AVG(duration_in_state) as avg_duration')
        .joins(:user)
        .includes(:user)
        .map do |log|
          {
            user: log.user,
            transitions: log.transition_count,
            average_duration: log.avg_duration&.to_i
          }
        end
    end
  end
end
