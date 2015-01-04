module API
  module V3
    module Relations
      class RelationsAPI < ::Cuba
        include API::Helpers
        include API::V3::Utilities::PathHelper

        define do
          res.headers['Content-Type'] = 'application/json; charset=utf-8'

          # params do
          #  optional :to_id, desc: 'Id of related work package'
          #  optional :relation_type, desc: 'Type of relationship'
          #  optional :delay
          # end
          on post do
            authorize(:manage_work_package_relations, context: @work_package.project)
            declared_params = declared(req.params).reject { |key, value| key.to_sym == :id || value.nil? }

            relation = @work_package.new_relation.tap do |r|
              r.to = WorkPackage.visible.find_by_id(declared_params['to_id'].match(/\d+/).to_s)
              r.relation_type = declared_params['relation_type']
              r.delay = declared_params['delay_id']
            end

            if relation.valid? && relation.save
              representer = ::API::V3::WorkPackages::RelationRepresenter.new(relation, work_package: relation.to)
              res.write representer.to_json
            else
              fail Errors::Validation.new(relation)
            end
          end

          on ':relation_id' do
            on delete do
              authorize(:manage_work_package_relations, context: @work_package.project)
              Relation.destroy(params[:relation_id])
              res.status = 204
            end
          end
        end
      end
    end
  end
end
