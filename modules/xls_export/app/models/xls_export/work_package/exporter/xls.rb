module XlsExport::WorkPackage::Exporter
  class XLS < WorkPackage::Exports::QueryExporter
    include ::XlsExport::Concerns::SpreadsheetBuilder

    def records
      work_packages
        .includes(:assigned_to, :type, :priority, :category, :version)
    end

    def spreadsheet_title
      I18n.t(:label_work_package_plural)
    end

    def with_descriptions
      ActiveModel::Type::Boolean.new.cast(options[:show_descriptions])
    end

    def with_relations
      ActiveModel::Type::Boolean.new.cast(options[:show_relations])
    end

    def enable!(singleton_module)
      singleton_class.prepend singleton_module
    end

    def export!
      enable! WithTimeZone
      enable! WithDescription if with_descriptions
      enable! WithRelations if with_relations

      success(spreadsheet.xls)
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
      super + [sanitize(work_package.description)]
    end

    def sanitize(string)
      Rails::Html::FullSanitizer.new.sanitize(string)
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
      lag = relation ? relation.lag : ""
      description = relation ? relation.description : ""
      relation_columns = ["", type, lag, description] + column_values(other)

      [""] + wp_columns + relation_columns
    end

    def relation_type(work_package, other, relation)
      if relation
        normalized = relation.relation_type_for(work_package)
        I18n.t("js.relation_labels.#{normalized}", default: normalized)
      elsif work_package.parent_id == other.id
        I18n.t "xls_export.child_of"
      elsif work_package.children.where(id: other.id).exists?
        I18n.t "xls_export.parent_of"
      end
    end

    def with_relations_headers
      [
        Relation.human_attribute_name(:relation_type),
        Relation.human_attribute_name(:lag),
        Relation.human_attribute_name(:description)
      ]
    end

    def work_package_relations(work_package)
      work_package.relations.visible
    end
  end
end
