require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module CardiacTest
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.cache_classes = true
    config.consider_all_requests_local       = true
    
    config.root = File.expand_path('../..', __FILE__)
    
    config.active_support.deprecation = :stderr
    config.active_support.escape_html_entities_in_json = true
    config.action_controller.perform_caching = false
    config.action_dispatch.show_exceptions = false
    config.action_controller.allow_forgery_protection    = false
    config.action_mailer.delivery_method = :test
    
    config.secret_key_base = "ABC" if config.respond_to?(:secret_key_base=)
    config.eager_load = false      if config.respond_to?(:eager_load)
    config.assets.enabled = false
    config.assets.version = '1.0'
    
  end
end