require 'active_attr/railtie'
require "cardiac/model/base"
require 'cardiac/log_subscriber'

module Cardiac
  class Railtie < Rails::Railtie

    initializer "cardiac.logger" do
      ActiveSupport.on_load(:cardiac) { self.logger ||= ::Rails.logger }
    end

    # Make the console output logging to STDERR (unless AR already did it).
    console do |app|
      unless defined? ::ActiveRecord::Base
        console = ActiveSupport::Logger.new(STDERR)
        Rails.logger.extend ActiveSupport::Logger.broadcast(console)
      end
    end
  end
end