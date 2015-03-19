require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# Configure Rails Environment
ENV["RAILS_ENV"] ||= "test"

require 'active_support/all'
require 'active_model'
require 'cardiac'

require 'awesome_print'

require 'rspec/core'

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}
  
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
