module DemoData
  class OverviewSeeder < Seeder
    include ::DemoData::References

    def seed_data!
      puts "*** Seeding Overview"

      Array(demo_data_for('projects')).each do |(_key, project_config)|
        next unless overview_config(project_config)

        puts "   -Creating overview for #{project_config[:name]}"

        overview = overview_from_config(project_config)

        overview_config(project_config)[:widgets].each do |widget_config|
          build_widget(overview, widget_config)
        end

        overview.save!
      end

      add_permission
    end

    def applicable?
      Grids::Overview.count.zero? && demo_projects_exist?
    end

    private

    def demo_projects_exist?
      identifiers = Array(demo_data_for('projects'))
        .map { |_key, project| project[:identifier] }

      identifiers
        .all? { |ident| Project.where(identifier: ident).exists? }
    end

    def build_widget(overview, widget_config)
      create_attachments!(overview, widget_config)

      widget_options = widget_config[:options]

      text_with_references(overview, widget_options)
      query_id_references(overview, widget_options)

      overview.widgets.build(widget_config.except(:attachments))
    end

    def create_attachments!(overview, attributes)
      Array(attributes[:attachments]).each do |file_name|
        attachment = overview.attachments.build
        attachment.author = User.admin.first
        attachment.file = File.new attachment_path(file_name)

        attachment.save!
      end
    end

    def attachment_path(file_name)
      ::Overviews::Engine.root.join(
        "config/locales/media/#{I18n.locale}/#{file_name}"
      )
    end

    def project_from_config(config)
      Project.find_by! identifier: config[:identifier]
    end

    def overview_from_config(project_config)
      params = overview_config(project_config)
               .slice(:row_count, :column_count)
               .merge(project: project_from_config(project_config))

      Grids::Overview
        .create(params)
    end

    def overview_config(project_config)
      project_config[:"project-overview"]
    end

    def text_with_references(overview, widget_options)
      if widget_options && widget_options[:text]
        widget_options[:text] = with_references(widget_options[:text], overview.project)
        widget_options[:text] = link_attachments(widget_options[:text], overview.attachments)
      end
    end

    def query_id_references(overview, widget_options)
      if widget_options && widget_options[:queryId]
        widget_options[:queryId] = with_references(widget_options[:queryId], overview.project)
      end
    end

    def add_permission
      Role
        .includes(:role_permissions)
        .where(role_permissions: { permission: 'edit_project' })
        .each do |role|
        role.add_permission!(:manage_overview)
      end
    end
  end
end
