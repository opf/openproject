Shindo.tests('AWS::AutoScaling | instances', ['aws', 'auto_scaling_m']) do

  pending # FIXME: instance#save is not defined
  #collection_tests(Fog::AWS[:auto_scaling].instances, {}, false)

end
