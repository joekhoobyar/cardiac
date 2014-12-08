require 'active_support/core_ext/module/delegation'
require 'factory_girl'
require 'fake_web'

# Adapted from factory_girl_remote_strategy
#
# @see https://github.com/shhavel/factory_girl_remote_strategy
module Cardiac
  module Model
    class FactoryGirlRemoteStrategy
      def initialize
        @strategy = FactoryGirl.strategy_by_name(:build).new
      end

      delegate :association, to: :@strategy

      def result(evaluation)
        @strategy.result(evaluation).tap do |model|
          FakeWeb.register_uri(:get, resource_url(model), body: resource_payload(model), content_type: 'application/json')
          FakeWeb.register_uri(:put, resource_url(model), body: resource_payload(model), content_type: 'application/json')
          evaluation.notify(:after_remote, model) # runs after(:remote) callback
        end
      end
      
    private
    
      def resource_url(model)
        model.class.identify(model).to_resource.to_url
      end
    
      def resource_payload(model)
        model.serializable_hash.to_json
      end
    end

    class FactoryGirlRemoteNotFoundStrategy < FactoryGirlRemoteStrategy
      def result(evaluation)
        @strategy.result(evaluation).tap do |model|
          FakeWeb.register_uri(:get, resource_url(model), body: '{}', content_type: 'application/json', status: 404)
        end
      end
    end

    ::FactoryGirl.register_strategy(:remote, FactoryGirlRemoteStrategy)
    ::FactoryGirl.register_strategy(:remote_not_found, FactoryGirlRemoteNotFoundStrategy)
  end
end
