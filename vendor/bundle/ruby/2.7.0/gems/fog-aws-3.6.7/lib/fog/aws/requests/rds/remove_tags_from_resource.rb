module Fog
  module AWS
    class RDS
      class Real
        # removes tags from a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_RemoveTagsFromResource.html
        # ==== Parameters
        # * rds_id <~String> - name of the RDS instance whose tags are to be retrieved
        # * keys <~Array> A list of String keys for the tags to remove
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def remove_tags_from_resource(rds_id, keys)
          request(
            { 'Action'        => 'RemoveTagsFromResource',
              'ResourceName'  => "arn:aws:rds:#{@region}:#{owner_id}:db:#{rds_id}",
              :parser         => Fog::Parsers::AWS::RDS::Base.new,
            }.merge(Fog::AWS.indexed_param('TagKeys.member.%d', keys))
          )
        end
      end

      class Mock
        def remove_tags_from_resource(rds_id, keys)
          response = Excon::Response.new
          if server = self.data[:servers][rds_id]
            keys.each {|key| self.data[:tags][rds_id].delete key}
            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id }
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
