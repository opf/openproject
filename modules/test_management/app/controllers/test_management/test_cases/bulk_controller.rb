# frozen_string_literal: true

module TestManagement
  module TestCases
    class BulkController < ApplicationController
      menu_item :test_management

      include OpTurbo::ComponentStream

      helper TestManagement::TestCasesHelper

      before_action :find_project_by_project_id
      before_action :authorize
      before_action :find_test_cases
      before_action :load_suites, only: %i[edit update move copy]

      NO_CHANGE = "no_change"

      def edit
        @attributes = {}
      end

      def delete_dialog
        respond_with_dialog TestManagement::TestCases::BulkDeleteDialogComponent.new(
          test_cases: @test_cases,
          project: @project
        )
      end

      def update
        call = BulkUpdateService.new(user: current_user, test_cases: @test_cases)
                                .call(attributes_for_update)

        if call.success?
          flash[:notice] = t("test_management.cases.bulk.updated", count: @test_cases.size)
          redirect_to project_test_management_test_cases_path(@project)
        else
          flash.now[:error] = call.errors.full_messages.to_sentence
          render :edit, status: :unprocessable_entity
        end
      end

      def move
        suite_id = normalize_suite_id(params[:suite_id])
        call = BulkUpdateService.new(user: current_user, test_cases: @test_cases)
                                .call(suite_id:)

        if call.success?
          flash[:notice] = t("test_management.cases.bulk.moved", count: @test_cases.size)
        else
          flash[:error] = call.errors.full_messages.to_sentence
        end
        redirect_to project_test_management_test_cases_path(@project)
      end

      def copy
        suite_id = normalize_suite_id(params[:suite_id])
        failures = []
        created = 0

        @test_cases.each do |test_case|
          result = CopyService.new(user: current_user, model: test_case).call(suite_id:)
          if result.success?
            created += 1
          else
            failures << "#{test_case.formatted_id}: #{result.errors.full_messages.to_sentence}"
          end
        end

        if failures.empty?
          flash[:notice] = t("test_management.cases.bulk.copied", count: created)
        else
          flash[:error] = failures.join(" ")
        end
        redirect_to project_test_management_test_cases_path(@project, suite_id:)
      end

      def destroy
        failures = []
        @test_cases.each do |test_case|
          call = DeleteService.new(user: current_user, model: test_case).call
          failures << "#{test_case.formatted_id}: #{call.errors.full_messages.to_sentence}" unless call.success?
        end

        if failures.empty?
          flash[:notice] = t("test_management.cases.bulk.deleted", count: @test_cases.size)
        else
          flash[:error] = failures.join(" ")
        end
        redirect_to project_test_management_test_cases_path(@project)
      end

      private

      def find_test_cases
        ids = Array(params[:ids]).map(&:to_i).uniq
        @test_cases = @project.tm_test_cases.not_deleted.where(id: ids).order(:id).to_a
        return if @test_cases.any?

        flash[:error] = t("test_management.cases.bulk.none_selected")
        redirect_to project_test_management_test_cases_path(@project)
      end

      def load_suites
        @suites = @project.tm_suites.ordered.to_a
      end

      def attributes_for_update
        return {} unless params.key?(:test_case)

        raw = params.expect(
          test_case: %i[title description preconditions priority status automated
                        automation_reference suite_id label_names work_package_ids
                        update_work_packages]
        ).to_h.with_indifferent_access

        transform_bulk_attributes(raw)
      end

      def transform_bulk_attributes(raw)
        attrs = {}

        %w[title description preconditions priority status automation_reference label_names].each do |key|
          next unless raw.key?(key)

          value = raw[key].to_s
          next if value.blank? || value == NO_CHANGE

          attrs[key] = value
        end

        if raw.key?(:automated) && raw[:automated].present? && raw[:automated] != NO_CHANGE
          attrs[:automated] = ActiveModel::Type::Boolean.new.cast(raw[:automated])
        end

        if raw.key?(:suite_id) && raw[:suite_id].present? && raw[:suite_id] != NO_CHANGE
          attrs[:suite_id] = normalize_suite_id(raw[:suite_id])
        end

        if raw[:update_work_packages] == "1"
          attrs[:work_package_ids] = raw[:work_package_ids].to_s
        end

        attrs
      end

      def normalize_suite_id(value)
        return nil if value.blank? || value.to_s.in?(%w[root none])

        value.to_i
      end
    end
  end
end
