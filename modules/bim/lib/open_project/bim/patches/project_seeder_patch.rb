module OpenProject::Bim::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def project_data_seeders(project, key)
      data = super

      if OpenProject::Configuration.bim?
        [
          ::Bim::DemoData::BcfXmlSeeder.new(project, key),
          ::Bim::DemoData::IfcModelSeeder.new(project, key)
        ] + data
      else
        data
      end
    end
  end
end
