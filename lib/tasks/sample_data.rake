namespace :sample_data do

  desc "Create the given number of fake projects"
  task :projects, [:nr_of_projects] => :environment do |task, args|
    puts "Creating #{args[:nr_of_projects]} fake projects"

    args[:nr_of_projects].to_i.times do |i|
      project = Project.create(name: Faker::Commerce.product_name,
                               identifier: "#{Faker::Code.isbn}-#{i}",
                               description: Faker::Lorem.paragraph(5),
                               types: Type.all,
                               is_public: true
      )

      puts "created: #{project.name}"
    end

    puts "#{args[:nr_of_projects]} fake projects created"

  end


end
