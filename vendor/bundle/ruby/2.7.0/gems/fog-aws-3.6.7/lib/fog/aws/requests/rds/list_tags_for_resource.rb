module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/tag_list_parser'

        # returns a Hash of tags for a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ListTagsForResource.html
        # ==== Parameters
        # * rds_id <~String> - name of the RDS instance whose tags are to be retrieved
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def list_tags_for_resource(rds_id)
          request(
            'Action'        => 'ListTagsForResource',
            'ResourceName'  => "arn:aws:rds:#{@region}:#{owner_id}:db:#{rds_id}",
            :parser         => Fog::Parsers::AWS::RDS::TagListParser.new
          )
        end
      end

      class Mock
        def list_tags_for_resource(rds_id)
          response = Excon::Response.new
          if server = self.data[:servers][rds_id]
            response.status = 200
            response.body = {
              "ListTagsForResourceResult" =>
                {"TagList" =>  self.data[:tags][rds_id]}
            }
            response
          else
            raise Fog::AWS::RDS::NotFound.new("DBInstance #{rds_id} not found")
          end
        end
      end
    end
  end
end
