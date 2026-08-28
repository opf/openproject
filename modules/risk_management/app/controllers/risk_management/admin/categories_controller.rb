# frozen_string_literal: true

module RiskManagement
  module Admin
    class CategoriesController < ApplicationController
      layout "admin"
      menu_item :risk_management_settings
      before_action :require_admin
      before_action :find_category, only: %i[edit update destroy]

      def index
        @categories = RiskCategory.order(:position)
      end

      def new
        @category = RiskCategory.new(active: true)
      end

      def edit; end

      def create
        @category = RiskCategory.new(category_params)
        @category.position = RiskCategory.maximum(:position).to_i + 1

        save_or_render(:new)
      end

      def update
        @category.assign_attributes(category_params)

        save_or_render(:edit)
      end

      def destroy
        @category.update!(active: false)
        redirect_to risk_management_admin_categories_path, notice: I18n.t(:notice_successful_update)
      end

      private

      def find_category
        @category = RiskCategory.find(params.expect(:id))
      end

      def category_params
        params.expect(risk_management_risk_category: %i[name color_id active])
      end

      def save_or_render(template)
        if @category.save
          redirect_to risk_management_admin_categories_path, notice: I18n.t(:notice_successful_update)
        else
          render template, status: :unprocessable_entity
        end
      end
    end
  end
end
