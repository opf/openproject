Shindo.tests("AWS::RDS | event subscriptions", ['aws', 'rds']) do
  pending unless Fog.mocking?
  params = {:id => "fog", :sns_topic_arn => 'arn:aws:sns:us-east-1:12345678910:fog'}

  collection_tests(Fog::AWS[:rds].event_subscriptions, params)
end
