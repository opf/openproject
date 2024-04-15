module OpenProject::Bim::Patches::RootSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_basic_data
      if OpenProject::Configuration.bim?
        print_status "*** Seeding basic data for bim edition"
        ::Bim::BasicDataSeeder.new(seed_data).seed!
      else
        super
      end
    end
  end
end
