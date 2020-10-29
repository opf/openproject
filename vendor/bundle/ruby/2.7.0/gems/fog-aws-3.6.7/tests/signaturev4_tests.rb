# encoding: utf-8

Shindo.tests('AWS | signaturev4', ['aws']) do
  @now = Fog::Time.utc(2011, 9, 9, 23, 36, 0)

  # These testcases are from http://docs.amazonwebservices.com/general/latest/gr/signature-v4-test-suite.html
  @signer = Fog::AWS::SignatureV4.new('AKIDEXAMPLE', 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY', 'us-east-1', 'host')

  tests('get-vanilla') do
    returns(@signer.sign({ headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470'
    end
  end

  tests('get-headers-mixed-case-headers') do
    returns(@signer.sign({ headers: { 'HOST' => 'host.foo.com', 'date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470'
    end
  end

  tests('get-vanilla-query-order-key with symbol keys') do
    returns(@signer.sign({ query: { a: 'foo', b: 'foo' }, headers: { Host: 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT'}, method: :get, path: '/' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=0dc122f3b28b831ab48ba65cb47300de53fbe91b577fe113edac383730254a3b'
    end
  end

  tests('get-vanilla-query-order-key') do
    returns(@signer.sign({ query: { a: 'foo', b: 'foo' }, headers: { Host: 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT'}, :method => :get, :path => '/'}, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=0dc122f3b28b831ab48ba65cb47300de53fbe91b577fe113edac383730254a3b'
    end
  end

  tests('get-unreserved') do
    returns(@signer.sign({ headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=830cc36d03f0f84e6ee4953fbe701c1c8b71a0372c63af9255aa364dd183281e'
    end
  end

  tests('post-x-www-form-urlencoded-parameter') do
    returns(@signer.sign({ headers: { 'Content-type' => 'application/x-www-form-urlencoded; charset=utf8', 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :post, path: '/',
                          body: 'foo=bar' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=content-type;date;host, Signature=b105eb10c6d318d2294de9d49dd8b031b55e3c3fe139f2e637da70511e9e7b71'
    end
  end

  tests('get with relative path') do
    returns(@signer.sign({ query: {}, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/foo/bar/../..' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470'
    end
  end

  tests('get with pointless .') do
    returns(@signer.sign({ query: {}, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/./foo' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=910e4d6c9abafaf87898e1eb4c929135782ea25bb0279703146455745391e63a'
    end
  end

  tests('get with repeated / ') do
    returns(@signer.sign({ query: {}, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '//' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470'
    end
  end

  tests('get with repeated // inside path') do
    returns(@signer.sign({ query: {}, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/foo//bar//baz' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b250c85c72c5d7c33f67759c7a1ad79ea381cf62105290cecd530af2771575d4'
    end
  end

  tests('get with repeated trailing / ') do
    returns(@signer.sign({ query: {}, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '//foo//' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b00392262853cfe3201e47ccf945601079e9b8a7f51ee4c3d9ee4f187aa9bf19'
    end
  end

  tests('get signature as components') do
    returns(@signer.signature_parameters({ query: { 'a' => 'foo', 'b' => 'foo' }, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/'}, @now)) do
      {
        'X-Amz-Algorithm' => 'AWS4-HMAC-SHA256',
        'X-Amz-Credential' => 'AKIDEXAMPLE/20110909/us-east-1/host/aws4_request',
        'X-Amz-SignedHeaders' => 'date;host',
        'X-Amz-Signature' => 'a6c6304682c74bcaebeeab2fdfb8041bbb39c6976300791a283057bccf333fb2'
      }
    end
  end

  tests('inject body sha') do
    returns(@signer.signature_parameters({ query: { 'a' => 'foo', 'b' => 'foo' }, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '/' }, @now, 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD')) do
      {
        'X-Amz-Algorithm' => 'AWS4-HMAC-SHA256',
        'X-Amz-Credential' => 'AKIDEXAMPLE/20110909/us-east-1/host/aws4_request',
        'X-Amz-SignedHeaders' => 'date;host',
        'X-Amz-Signature' => '22c32bb0d0b859b94839de4e9360bca1806e73d853f5f97ae0d849f0bdf42fb0'
      }
    end
  end

  tests('s3 signer does not normalize path') do
    signer = Fog::AWS::SignatureV4.new('AKIDEXAMPLE', 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY', 'us-east-1', 's3')
    returns(signer.sign({ query: {}, headers: { 'Host' => 'host.foo.com', 'Date' => 'Mon, 09 Sep 2011 23:36:00 GMT' }, method: :get, path: '//foo/../bar/./' }, @now)) do
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/s3/aws4_request, SignedHeaders=date;host, Signature=72407ad06b8e5750360f42e8aad9f33a0be363bcfeecdcae0aea58c99709fb4a'
    end
  end

  Fog::Time.now = ::Time.now
end
