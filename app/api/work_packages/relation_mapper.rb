module WorkPackages
  class RelationMapper < Yaks::Mapper
    link :self, '/api/v3/work_packages/{work_package_id}/relations'

    attributes :id

    def work_package_id
      1
    end
  end
end
