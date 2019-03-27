module BimSeeder
  module RootSeeder
    def seed_basic_data
      ::BimSeeder::BasicDataSeeder.new.seed!
    end
  end
end

RootSeeder.prepend BimSeeder::RootSeeder
