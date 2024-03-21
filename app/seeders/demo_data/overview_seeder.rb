module DemoData
  class OverviewSeeder < Seeder
    include CreateAttachments
    include References

    def seed_data!
      print_status "*** Seeding Overview"

      seed_data.each_data('projects') do |project_data|
        overview_data = overview_data(project_data)
        next unless overview_data

        print_status "   -Creating overview for #{project_data.lookup('name')}"

        overview = create_overview(overview_data, project_data)

        overview_data.each('widgets') do |widget_config|
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
      identifiers = []
      seed_data.each_data('projects') do |project_data|
        identifiers << project_data.lookup('identifier')
      end

      identifiers.all? { |identifier| Project.exists?(identifier:) }
    end

    def build_widget(overview, widget_config)
      create_attachments!(overview, widget_config)

      widget_options = widget_config['options']

      text_with_references(overview, widget_options)
      query_id_references(overview, widget_options)

      overview.widgets.build(widget_config.except('attachments'))
    end

    def find_project(project_data)
      Project.find_by!(identifier: project_data.lookup('identifier'))
    end

    def create_overview(overview_data, project_data)
      Grids::Overview.create(
        row_count: overview_data.lookup('row_count'),
        column_count: overview_data.lookup('column_count'),
        project: find_project(project_data)
      )
    end

    def overview_data(project_data)
      project_data.lookup('project-overview')
    end

    def text_with_references(overview, widget_options)
      if widget_options && widget_options['text']
        widget_options['text'] = with_references(widget_options['text'])
        widget_options['text'] = link_attachments(widget_options['text'], overview.attachments)
      end
    end

    def query_id_references(_overview, widget_options)
      if widget_options && widget_options['queryId']
        widget_options['queryId'] = with_references(widget_options['queryId'])
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
