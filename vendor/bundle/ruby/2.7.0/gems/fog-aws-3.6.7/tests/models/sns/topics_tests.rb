Shindo.tests("AWS::SNS | topics", ['aws', 'sns']) do
  pending unless Fog.mocking?
  params = {:id => 'arn:aws:sns:us-east-1:12345678910:fog'}

  collection_tests(Fog::AWS[:sns].topics, params)
end
