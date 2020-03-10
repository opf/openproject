module OpenProject::Bim::Patches::RootSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_basic_data
      if OpenProject::Configuration.bim?
        puts "*** Seeding basic data for bim edition"
        ::Bim::BasicDataSeeder.new.seed!
      else
        super
      end
    end
  end
end
