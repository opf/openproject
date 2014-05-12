module Projects
  class ProjectMapper < Yaks::Mapper
    link :self, '/api/v3/projects/{id}'
    link :root, '/api/v3'
    link :createChildren, '/api/v3/projects?parent_id={id}', method: :post
    link :update, '/api/v3/projects/{id}', method: :patch
    link :delete, '/api/v3/projects/{id}', method: :delete
    link :version, '/api/v3/versions?filter[project_id]={id}'
    link :responsible, '/api/v3/users/{responsible_id}'
    link :members, '/api/v3/projects/{id}/members'
    link :workPackages, '/api/v3/work_packages?filter[project_id]={id}'
    link :createWorkPackages, '/api/v3/work_packages', method: :post
    link :possibleResponsibles, '/api/v3/projects/{id}/possible_responsibles'

    attributes :id, :name, :description, :createdAt, :updatedAt,  :summary

    has_one :responsible, mapper: Users::UserMapper
    has_many :users, mapper: Users::UserMapper, as: :members

    def createdAt
      object.created_on.strftime("at %I:%M%p")
    end

    def updatedAt
      object.updated_on.strftime("at %I:%M%p")
    end
  end
end
