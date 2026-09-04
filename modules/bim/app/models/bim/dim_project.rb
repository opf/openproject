# frozen_string_literal: true

module Bim
  # Dimension table for projects (Type 2 Slowly Changing Dimension)
  # Tracks historical changes to project attributes for accurate time-series analysis
  class DimProject < ApplicationRecord
    self.table_name = 'bim_dim_projects'

    # Associations
    belongs_to :project
    has_many :portfolio_metrics, class_name: 'Bim::PortfolioMetric', foreign_key: :dim_project_id
    has_many :model_predictions, class_name: 'Bim::ModelPrediction', foreign_key: :dim_project_id

    # Validations
    validates :project_id, presence: true
    validates :project_name, presence: true
    validates :project_type, inclusion: { in: %w[commercial residential infrastructure industrial mixed], allow_nil: true }
    validates :project_size, inclusion: { in: %w[small medium large mega], allow_nil: true }
    validates :client_segment, inclusion: { in: %w[public private government mixed], allow_nil: true }
    validates :valid_from, presence: true

    # Scopes
    scope :current, -> { where(is_current: true) }
    scope :active, -> { where(active: true) }
    scope :by_type, ->(type) { where(project_type: type) }
    scope :by_size, ->(size) { where(project_size: size) }
    scope :by_region, ->(region) { where(region: region) }
    scope :by_division, ->(division) { where(division: division) }
    scope :by_client_segment, ->(segment) { where(client_segment: segment) }
    scope :contributing_to_benchmarks, -> { where(contribute_to_benchmarks: true) }

    # Class methods
    class << self
      # Get or create current dimension record for a project
      def for_project(project, as_of: Time.current)
        dim_record = where(project_id: project.id, is_current: true).first

        if dim_record
          # Check if project attributes have changed (SCD Type 2)
          if attributes_changed?(dim_record, project)
            # Close current record and create new one
            dim_record.update!(valid_to: as_of, is_current: false)
            dim_record = create_from_project(project, as_of)
          end
        else
          # Create initial dimension record
          dim_record = create_from_project(project, as_of)
        end

        dim_record
      end

      # Create dimension record from project
      def create_from_project(project, valid_from = Time.current)
        create!(
          project: project,
          project_name: project.name,
          project_identifier: project.identifier,
          project_type: infer_project_type(project),
          project_size: infer_project_size(project),
          region: project.custom_field_value('region'),
          division: project.custom_field_value('division'),
          client_segment: infer_client_segment(project),
          start_date: project.custom_field_value('start_date'),
          target_completion_date: project.custom_field_value('target_completion_date'),
          total_budget: project.custom_field_value('budget')&.to_f,
          active: project.active?,
          contribute_to_benchmarks: project.custom_field_value('contribute_to_benchmarks') == 'true',
          metadata: extract_metadata(project),
          valid_from: valid_from,
          valid_to: '9999-12-31',
          is_current: true
        )
      end

      # Check if tracked attributes have changed
      def attributes_changed?(dim_record, project)
        dim_record.project_name != project.name ||
          dim_record.project_type != infer_project_type(project) ||
          dim_record.project_size != infer_project_size(project) ||
          dim_record.region != project.custom_field_value('region') ||
          dim_record.division != project.custom_field_value('division')
      end

      # Infer project type from project attributes
      def infer_project_type(project)
        # Logic to determine project type from custom fields or name patterns
        type_field = project.custom_field_value('project_type')
        return type_field if type_field.present?

        # Pattern matching as fallback
        name_lower = project.name.downcase
        return 'commercial' if name_lower.include?('office') || name_lower.include?('retail')
        return 'residential' if name_lower.include?('residential') || name_lower.include?('apartment')
        return 'infrastructure' if name_lower.include?('bridge') || name_lower.include?('road')
        return 'industrial' if name_lower.include?('factory') || name_lower.include?('warehouse')

        'mixed'
      end

      # Infer project size based on budget or other metrics
      def infer_project_size(project)
        size_field = project.custom_field_value('project_size')
        return size_field if size_field.present?

        budget = project.custom_field_value('budget')&.to_f
        return nil unless budget

        if budget >= 100_000_000
          'mega'
        elsif budget >= 10_000_000
          'large'
        elsif budget >= 1_000_000
          'medium'
        else
          'small'
        end
      end

      # Infer client segment
      def infer_client_segment(project)
        segment_field = project.custom_field_value('client_segment')
        return segment_field if segment_field.present?

        client_name = project.custom_field_value('client')&.downcase || ''
        return 'government' if client_name.include?('ministry') || client_name.include?('department')
        return 'public' if client_name.include?('council') || client_name.include?('authority')

        'private'
      end

      # Extract metadata from project
      def extract_metadata(project)
        {
          description: project.description,
          custom_fields: project.custom_field_values.map { |cfv| [cfv.custom_field.name, cfv.value] }.to_h,
          created_at: project.created_at,
          updated_at: project.updated_at
        }
      end
    end

    # Instance methods

    # Get snapshot of this dimension at a specific point in time
    def self.as_of(date)
      where('valid_from <= ? AND valid_to > ?', date, date)
    end

    # Close this dimension record (for SCD Type 2)
    def close!(closing_date = Time.current)
      update!(valid_to: closing_date, is_current: false)
    end

    # Display name
    def display_name
      "#{project_name} (#{project_type&.capitalize}, #{project_size&.capitalize})"
    end
  end
end
