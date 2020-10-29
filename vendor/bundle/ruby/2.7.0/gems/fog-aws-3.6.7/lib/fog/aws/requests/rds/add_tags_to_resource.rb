module Fog
  module AWS
    class RDS
      class Real
        # adds tags to a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_AddTagsToResource.html
        # ==== Parameters
        # * rds_id <~String> - name of the RDS instance whose tags are to be retrieved
        # * tags <~Hash> A Hash of (String) key-value pairs
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def add_tags_to_resource(rds_id, tags)
          keys    = tags.keys.sort
          values  = keys.map {|key| tags[key]}
          request({
              'Action'        => 'AddTagsToResource',
              'ResourceName'  => "arn:aws:rds:#{@region}:#{owner_id}:db:#{rds_id}",
              :parser         => Fog::Parsers::AWS::RDS::Base.new,
            }.merge(Fog::AWS.indexed_param('Tags.member.%d.Key', keys)).
              merge(Fog::AWS.indexed_param('Tags.member.%d.Value', values)))
        end
      end

      class Mock
        def add_tags_to_resource(rds_id, tags)
          response = Excon::Response.new
          if server = self.data[:servers][rds_id]
            self.data[:tags][rds_id].merge! tags
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
