Shindo.tests('Fog::CDN[:aws] | CDN requests', ['aws', 'cdn']) do

  @cf_connection = Fog::CDN[:aws]

  tests('distributions success') do

    test('get current ditribution list count') do

      @count= 0
      response = @cf_connection.get_distribution_list
      if response.status == 200
        @distributions = response.body['DistributionSummary']
        @count = @distributions.count
      end

      response.status == 200
    end

    test('create distribution') {

      result = false

      response = @cf_connection.post_distribution('S3Origin' => { 'DNSName' => 'test_cdn.s3.amazonaws.com'}, 'Enabled' => true)
      if response.status == 201
        @dist_id = response.body['Id']
        @etag = response.headers['ETag']
        @caller_reference = response.body['DistributionConfig']['CallerReference']
        if (@dist_id.length > 0)
          result = true
        end
      end

      result
    }

    test("get info on distribution #{@dist_id}") {

      result = false

      response = @cf_connection.get_distribution(@dist_id)
      if response.status == 200
        @etag = response.headers['ETag']
        status = response.body['Status']
        if ((status == 'Deployed') or (status == 'InProgress')) and not @etag.nil?
          result = true
        end
      end

      result
    }

    test('list distributions') do

      result = false

      response = @cf_connection.get_distribution_list
      if response.status == 200
        distributions = response.body['DistributionSummary']
        if (distributions.count > 0)
          dist = distributions[0]
          dist_id = dist['Id']
        end
        max_items = response.body['MaxItems']

        if (dist_id.length > 0) and (max_items > 0)
          result = true
        end

      end

      result
    end

    test("invalidate paths") {

      response = @cf_connection.post_invalidation(@dist_id, ["/test.html", "/path/to/file.html"])
      if response.status == 201
        @invalidation_id = response.body['Id']
      end

      response.status == 201
    }

    test("list invalidations") {

      result = false

      response = @cf_connection.get_invalidation_list(@dist_id)
      if response.status == 200
        if response.body['InvalidationSummary'].find { |f| f['Id'] == @invalidation_id }
          result = true
        end
      end

      result
    }

    test("get invalidation information") {

      result = false

      response = @cf_connection.get_invalidation(@dist_id, @invalidation_id)
      if response.status == 200
        paths = response.body['InvalidationBatch']['Path'].sort
        status = response.body['Status']
        if status.length > 0 and paths == [ '/test.html', '/path/to/file.html' ].sort
          result = true
        end
      end

      result
    }

    test("disable distribution #{@dist_id} - can take 15 minutes to complete...") {

      result = false

      response = @cf_connection.put_distribution_config(@dist_id, @etag, 'S3Origin' => { 'DNSName' => 'test_cdn.s3.amazonaws.com'}, 'Enabled' => false, 'CallerReference' => @caller_reference)
      if response.status == 200
        @etag = response.headers['ETag']
        unless @etag.nil?
          result = true
        end
      end

      result
    }

    test("remove distribution #{@dist_id}") {

      result = true

      # unfortunately you can delete only after a distribution becomes Deployed
      Fog.wait_for {
        response = @cf_connection.get_distribution(@dist_id)
        @etag = response.headers['ETag']
        response.status == 200 and response.body['Status'] == 'Deployed'
      }

      response = @cf_connection.delete_distribution(@dist_id, @etag)
      if response.status != 204
        result = false
      end

      result
    }
  end

  tests('streaming distributions success') do

    test('get current streaming ditribution list count') do

      @count= 0
      response = @cf_connection.get_streaming_distribution_list
      if response.status == 200
        @distributions = response.body['StreamingDistributionSummary']
        @count = @distributions.count
      end

      response.status == 200
    end

    test('create distribution') {

      result = false

      response = @cf_connection.post_streaming_distribution('S3Origin' => { 'DNSName' => 'test_cdn.s3.amazonaws.com'}, 'Enabled' => true)
      if response.status == 201
        @dist_id = response.body['Id']
        @etag = response.headers['ETag']
        @caller_reference = response.body['StreamingDistributionConfig']['CallerReference']
        if (@dist_id.length > 0)
          result = true
        end
      end

      result
    }

    test("get info on distribution #{@dist_id}") {

      result = false

      response = @cf_connection.get_streaming_distribution(@dist_id)
      if response.status == 200
        @etag = response.headers['ETag']
        status = response.body['Status']
        if ((status == 'Deployed') or (status == 'InProgress')) and not @etag.nil?
          result = true
        end
      end

      result
    }

    test('list streaming distributions') do

      result = false

      response = @cf_connection.get_streaming_distribution_list
      if response.status == 200
        distributions = response.body['StreamingDistributionSummary']
        if (distributions.count > 0)
          dist = distributions[0]
          dist_id = dist['Id']
        end
        max_items = response.body['MaxItems']

        if (dist_id.length > 0) and (max_items > 0)
          result = true
        end

      end

      result
    end

    test("disable distribution #{@dist_id} - can take 15 minutes to complete...") {

      result = false

      response = @cf_connection.put_streaming_distribution_config(@dist_id, @etag, 'S3Origin' => { 'DNSName' => 'test_cdn.s3.amazonaws.com'}, 'Enabled' => false, 'CallerReference' => @caller_reference)
      if response.status == 200
        @etag = response.headers['ETag']
        unless @etag.nil?
          result = true
        end
      end

      result
    }

    test("remove distribution #{@dist_id}") {

      result = true

      # unfortunately you can delete only after a distribution becomes Deployed
      Fog.wait_for {
        response = @cf_connection.get_streaming_distribution(@dist_id)
        @etag = response.headers['ETag']
        response.status == 200 and response.body['Status'] == 'Deployed'
      }

      response = @cf_connection.delete_streaming_distribution(@dist_id, @etag)
      if response.status != 204
        result = false
      end

      result
    }
  end
end
