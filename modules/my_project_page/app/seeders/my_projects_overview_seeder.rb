module DemoData
  module MyProjectPage
    class MyProjectsOverviewSeeder < Seeder
      include ::DemoData::References

      def seed_data!
        puts "*** Seeding MyProjectsOverview"

        Array(translate_with_base_url("seeders.demo_data.projects")).each do |key, project|
          puts "   -Creating overview for #{project[:name]}"

          if config = project[:"project-overview"]
            project = Project.find_by! identifier: project[:identifier]

            mpo = MyProjectsOverview.create!(
              project: project,
              left: Array(config[:left]).map { |left| area left, project },
              right: Array(config[:right]).map { |right| area right, project },
              top: Array(config[:top]).map { |top| area top, project }
            )

            [:left, :right, :top].each do |a|
              Array(config[a]).each do |cfg|
                create_attachments! mpo, a, cfg if cfg.is_a? Hash
              end
            end
          end
        end
      end

      def applicable?
        MyProjectsOverview.count.zero? && demo_projects_exist?
      end

      private

      def demo_projects_exist?
        identifiers = Array(I18n.t("seeders.demo_data.projects"))
          .map { |_key, project| project[:identifier] }

        identifiers
          .all? { |ident| Project.where(identifier: ident).exists? }
      end

      def area(config, project)
        return config if config.is_a? String
        return config[:block] if config[:block].present?

        [config[:id], config[:title], with_references(config[:content], project)]
      end

      def create_attachments!(my_project_overview, area, attributes)
        Array(attributes[:attachments]).each do |file_name|
          attachment = my_project_overview.attachments.build
          attachment.author = User.admin.first
          attachment.file = File.new attachment_path(file_name)

          attachment.save!
        end

        area_with_references = Array(my_project_overview.send(area)).map do |data|
          if data.is_a? String # single string referring to a block
            data
          else
            tag, title, content = data

            [tag, title, link_attachments(content, my_project_overview.attachments)]
          end
        end

        my_project_overview.update area => area_with_references
      end

      def attachment_path(file_name)
        OpenProject::MyProjectPage::Engine.root.join(
          "config/locales/media/#{I18n.locale}/#{file_name}"
        )
      end
    end
  end
end
