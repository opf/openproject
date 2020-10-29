Shindo.tests("AWS::RDS | event_subscription", ['aws', 'rds']) do
  pending unless Fog.mocking?

  name = 'fog'
  params = {:id => name, :sns_topic_arn => 'arn:aws:sns:us-east-1:12345678910:fog'}

  model_tests(Fog::AWS[:rds].event_subscriptions, params) do
  end
end
