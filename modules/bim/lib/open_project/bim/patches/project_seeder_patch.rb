module OpenProject::Bim::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def project_data_seeders(project, key)
      [
        ::Bim::DemoData::BcfXmlSeeder.new(project, key),
        ::Bim::DemoData::IfcModelSeeder.new(project, key)
      ] + super(project, key)
    end

    def seed_settings
      super
      Setting.attachment_max_size = 256000
    end
  end
end
