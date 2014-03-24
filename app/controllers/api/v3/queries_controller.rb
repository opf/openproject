

module Api
  module V3

    class QueriesController < ApplicationController
      unloadable

      include PaginationHelper
      include QueriesHelper
      include ::Api::V3::ApiController
      include ExtendedHTTP

      before_filter :find_optional_project

      def available_columns
        query = retrieve_query
        @available_columns = get_columns_for_json(query.available_columns)

        respond_to do |format|
          format.api
        end
      end

      private

      def get_columns_for_json(columns)
        columns.map do |column|
          { name: column.name,
            title: column.caption,
            sortable: column.sortable,
            groupable: column.groupable,
            custom_field: column.is_a?(QueryCustomFieldColumn) &&
                          column.custom_field.as_json(only: [:id, :field_format]),
            meta_data: get_column_meta(column)
          }
        end
      end

      def get_column_meta(column)
        # This is where we want to add column specific behaviour to instruct the front end how to deal with it
        # Needs to be things like user link,project link, datetime
        {
          data_type: column_data_type(column),
          link: !!(link_meta()[column.name]) ? link_meta()[column.name] : { display: false }
        }
      end

      def link_meta
        {
          subject: { display: true, model_type: "work_package" },
          type: { display: false },
          status: { display: false },
          priority: { display: false },
          parent: { display: true, model_type: "user" },
          assigned_to: { display: true, model_type: "user" },
          responsible: { display: true, model_type: "user" },
          author: { display: true, model_type: "user" },
          project: { display: true, model_type: "project" }
        }
      end

      def column_data_type(column)
        if column.is_a?(QueryCustomFieldColumn)
          return column.custom_field.field_format
        elsif (c = WorkPackage.columns_hash[column.name.to_s] and !c.nil?)
          return c.type.to_s
        elsif (c = WorkPackage.columns_hash[column.name.to_s + "_id"] and !c.nil?)
          return "object"
        else
          return "default"
        end
      end
    end

  end
end
