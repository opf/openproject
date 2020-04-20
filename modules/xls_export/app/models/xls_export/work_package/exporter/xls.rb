module XlsExport::WorkPackage::Exporter
  class XLS < WorkPackage::Exporter::Base
    include Redmine::I18n

    def current_user
      User.current
    end

    def with_descriptions
      options[:show_descriptions]
    end

    def with_relations
      options[:show_relations]
    end

    def work_packages
      super
        .includes(:assigned_to, :type, :priority, :category, :version)
    end

    def enable!(singleton_module)
      singleton_class.prepend singleton_module
    end

    def list
      enable! WithTimeZone
      enable! WithDescription if with_descriptions
      enable! WithRelations if with_relations

      yield success(spreadsheet.xls)
    end

    def success(content)
      WorkPackage::Exporter::Result::Success
        .new format: :xls,
             content: content,
             title: xls_export_filename,
             mime_type: 'application/vnd.ms-excel'
    end

    def spreadsheet
      sb = spreadsheet_builder

      add_headers! sb
      add_rows! sb
      set_column_format_options! sb

      sb
    end

    def add_headers!(spreadsheet)
      spreadsheet.add_headers headers, 0
    end

    def add_rows!(spreadsheet)
      rows.each do |row|
        spreadsheet.add_row row
      end
    end

    def rows
      work_packages.map do |work_package|
        row work_package
      end
    end

    def row(work_package)
      column_values(work_package)
    end

    def column_values(work_package)
      columns.collect do |column|
        column_value column, work_package
      end
    end

    def column_value(column, work_package)
      value = format_column_value column, work_package

      value.respond_to?(:name) ? value.name : value
    end

    def format_column_value(column, work_package)
      formatters[column].format work_package, column
    end

    def set_column_format_options!(spreadsheet)
      columns.each_with_index do |column, i|
        options = formatters[column].format_options column

        spreadsheet.add_format_option_to_column i, options
      end
    end

    def columns
      @columns ||= valid_export_columns
    end

    def formatters
      @formatters ||= OpenProject::XlsExport::Formatters.for_columns(columns)
    end

    def spreadsheet_builder
      OpenProject::XlsExport::SpreadsheetBuilder.new I18n.t(:label_work_package_plural)
    end

    def headers
      columns.map(&:caption)
    end

    def xls_export_filename
      sane_filename(
        "#{Setting.app_title} #{I18n.t(:label_work_package_plural)} \
         #{format_time_as_date(Time.now, '%Y-%m-%d')}.xls"
      )
    end
  end

  module WithTimeZone
    def format_column_value(column, work_package)
      value = super

      if value.is_a? ActiveSupport::TimeWithZone
        value.in_time_zone current_user.time_zone
      else
        value
      end
    end
  end

  module WithDescription
    def headers
      super + [WorkPackage.human_attribute_name(:description)]
    end

    def row(work_package)
      super + [work_package.description]
    end
  end

  module WithRelations
    def add_headers!(spreadsheet)
      headers_0 = [I18n.t(:label_work_package_plural)] +
                  columns.size.times.map { |_| "" } +
                  [I18n.t("js.work_packages.tabs.relations")]

      spreadsheet.add_headers headers_0, 0
      spreadsheet.add_headers headers, 1
    end

    def headers
      # The filtered work packages columns +
      # the relations columns +
      # the columns of the work packages connected by the relations.
      [""] + super + [""] + with_relations_headers + super
    end

    def rows
      super.flatten(1) # since we will now generate several rows for each original row
    end

    def row(work_package)
      wp_columns = super

      relatives = related_work_packages work_package

      if relatives.size > 0
        relatives.map do |other, rel|
          relation_row work_package, wp_columns, other, rel
        end
      else
        unrelated_row wp_columns
      end
    end

    module_function

    ##
    # Work packages both related explicitly through relation records
    # as well via their parent_id association (parent and children).
    #
    # @return Array A list of work package - relation tuples
    #               where the relation may be nil which indicates
    #               that the respective work package is either a
    #               parent or a child.
    def related_work_packages(work_package)
      family = ([work_package.parent].compact +
                work_package.children.order(:subject))
               .select { |wp| wp.visible? current_user }
               .map { |wp| [wp, nil] }

      family + relation_work_packages(work_package)
    end

    ##
    # Work packages related through explicit relation records.
    #
    # @return Array<Array<WorkPackage, Relation>> A list of work package - relation tuples.
    def relation_work_packages(work_package)
      relations = work_package_relations work_package

      relations.map { |rel| [rel.other_work_package(work_package), rel] }
    end

    def unrelated_row(wp_columns)
      [([""] + wp_columns)]
    end

    def relation_row(work_package, wp_columns, other, relation)
      type = relation_type work_package, other, relation
      delay = relation ? relation.delay : ""
      description = relation ? relation.description : ""
      relation_columns = ["", type, delay, description] + column_values(other)

      [""] + wp_columns + relation_columns
    end

    def relation_type(work_package, other, relation)
      if relation
        normalized = relation.relation_type_for(work_package)
        I18n.t("js.relation_labels.#{normalized}", default: normalized)
      elsif work_package.parent_id == other.id
        I18n.t 'xls_export.child_of'
      elsif work_package.children.where(id: other.id).exists?
        I18n.t 'xls_export.parent_of'
      end
    end

    def with_relations_headers
      [
        Relation.human_attribute_name(:relation_type),
        Relation.human_attribute_name(:delay),
        Relation.human_attribute_name(:description)
      ]
    end

    def work_package_relations(work_package)
      work_package.relations.direct.non_hierarchy.visible
    end
  end
end
