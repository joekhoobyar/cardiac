require 'active_attr/railtie'
require 'cardiac/model'
require 'cardiac/log_subscriber'

module Cardiac
  class Railtie < Rails::Railtie
    config.cardiac = ActiveSupport::OrderedOptions.new
    config.cardiac_model = ActiveSupport::OrderedOptions.new

    initializer "cardiac_model.logger" do
      ActiveSupport.on_load(:cardiac_model) do
        self.logger ||= ::Rails.logger
      end
    end

    # Make the console output logging to STDERR (unless AR already did it).
    console do |app|
      unless defined? ::ActiveRecord::Base
        console = ActiveSupport::Logger.new(STDERR)
        Rails.logger.extend ActiveSupport::Logger.broadcast(console)
      end
    end

    # Make sure that the model layer is already available when running a script.
    runner do
      require 'cardiac/model/base'
    end
  end
end