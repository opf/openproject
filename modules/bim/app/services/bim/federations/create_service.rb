# frozen_string_literal: true

module Bim
  module Federations
    class CreateService < BaseServices::Create
      def initialize(user:, project:)
        super(user: user)
        @project = project
      end

      protected

      def instance(params)
        federation = Bim::ModelFederation.new
        federation.project = @project
        federation.attributes = permitted_params(params)
        federation
      end

      def after_save(params)
        result = add_models_to_federation(params)
        return result if result.failure?

        if params[:auto_align]
          result = align_models
          return result if result.failure?
        end

        ServiceResult.success(result: instance)
      end

      private

      def permitted_params(params)
        params.slice(:name, :description, :base_point, :rotation, :units)
      end

      def add_models_to_federation(params)
        model_ids = params[:model_ids] || []

        model_ids.each do |model_id|
          ifc_model = Bim::IfcModels::IfcModel.find_by(id: model_id, project: @project)
          unless ifc_model
            return ServiceResult.failure(errors: "IFC Model #{model_id} not found")
          end

          discipline = detect_discipline(ifc_model)

          federation_model = instance.federation_models.build(
            ifc_model: ifc_model,
            discipline: discipline,
            transform: default_transform,
            display_order: instance.federation_models.size
          )

          unless federation_model.save
            return ServiceResult.failure(errors: federation_model.errors)
          end
        end

        ServiceResult.success
      end

      def detect_discipline(ifc_model)
        # Heuristic based on model title
        title = ifc_model.title.downcase

        return :architectural if title.match?(/arch|architecture/)
        return :structural if title.match?(/struct|structure/)
        return :mechanical if title.match?(/mech|hvac|mechanical/)
        return :electrical if title.match?(/elec|electrical/)
        return :plumbing if title.match?(/plumb|plumbing/)
        return :civil if title.match?(/civil/)
        return :landscape if title.match?(/landscape/)

        :other
      end

      def align_models
        alignment_service = AlignmentService.new(instance)
        alignment_service.call
      end

      def default_transform
        {
          translation: [0, 0, 0],
          rotation: [0, 0, 0],
          scale: [1, 1, 1]
        }
      end
    end
  end
end
