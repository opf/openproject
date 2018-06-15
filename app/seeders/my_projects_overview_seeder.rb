module DemoData
  module MyProjectPage
    class MyProjectsOverviewSeeder < Seeder
      def seed_data!
        puts "*** Seeding MyProjectsOverview"

        Array(I18n.t("seeders.demo_data.projects")).each do |key, project|
          puts "   -Creating overview for #{project[:name]}"

          if config = project[:"project-overview"]
            mpo = MyProjectsOverview.create!(
              project: Project.find_by(identifier: project[:identifier]),
              left: Array(config[:left]).map { |top| area top },
              right: Array(config[:right]).map { |top| area top },
              top: Array(config[:top]).map { |top| area top }
            )

            [:left, :right, :top].each do |a|
              Array(config[a]).each do |cfg|
                create_attachments! mpo, cfg if cfg.is_a? Hash
              end
            end
          end
        end
      end

      def applicable?
        MyProjectsOverview.count.zero?
      end

      private

      def area(config)
        return config if config.is_a? String

        [config[:id], config[:title], config[:content]]
      end

      def create_attachments!(my_project_overview, attributes)
        Array(attributes[:attachments]).each do |file_name|
          attachment = my_project_overview.attachments.build
          attachment.author = User.admin.first
          attachment.file = File.new attachment_path(file_name)

          attachment.save!
        end
      end

      def attachment_path(file_name)
        OpenProject::MyProjectPage::Engine.root.join(
          "config/locales/media/#{I18n.locale}/#{file_name}"
        )
      end
    end
  end
end
