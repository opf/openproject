module OpenProject::Bim::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def project_content_seeder_classes
      classes = []
      classes += bim_project_content_seeder_classes if OpenProject::Configuration.bim?
      classes += super
      classes
    end

    private

    def bim_project_content_seeder_classes
      [
        ::Bim::DemoData::BcfXmlSeeder,
        ::Bim::DemoData::IfcModelSeeder
      ]
    end
  end
end
