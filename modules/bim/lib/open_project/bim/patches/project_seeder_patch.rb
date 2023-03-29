module OpenProject::Bim::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def project_data_seeders(project, project_data)
      data = super

      if OpenProject::Configuration.bim?
        [
          ::Bim::DemoData::BcfXmlSeeder.new(project, project_data),
          ::Bim::DemoData::IfcModelSeeder.new(project, project_data)
        ] + data
      else
        data
      end
    end
  end
end
