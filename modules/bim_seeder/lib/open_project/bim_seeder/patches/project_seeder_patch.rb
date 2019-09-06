module OpenProject::BimSeeder::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def project_data_seeders(project, key)
      [::BimSeeder::DemoData::BcfXmlSeeder.new(project, key)] + super(project, key)
    end
  end
end
