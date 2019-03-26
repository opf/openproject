module BimSeeder
  module RootSeeder
    def seed_basic_data
      if OpenProject::Configuration['edition'] == 'bim'
        return ::BimSeeder::BasicDataSeeder.new.seed!
      end

      super
    end
  end
end

RootSeeder.prepend BimSeeder::RootSeeder
