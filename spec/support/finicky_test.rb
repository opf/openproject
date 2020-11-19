class FinickyTest
  # frontend not fast enough to bind click handlers on buttons?
  def self.wait_for_frontend_binding
    sleep ENV.fetch("FINICKY_TEST_WAIT_FOR_FRONTEND_BINDING", 1).to_i
  end
end
