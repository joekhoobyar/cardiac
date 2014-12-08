# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cardiac/version"

Gem::Specification.new do |s|
  s.name        = "cardiac"
  s.version     = Cardiac::VERSION
  s.authors     = ["Joe Khoobyar"]
  s.email       = ["joe@khoobyar.name"]
  s.homepage    = "http://github.com/cardiac/cardiac"
  s.license     = 'MIT'
  s.summary     = %q{ Cardiac: a REST modeling framework for Ruby }
  s.description = %q{
    This gem provides a thin facade around REST-ful resources, aiming to be closer to ActiveRecord than ActiveResource.
  }

  s.rubyforge_project = "cardiac"
  
  s.required_ruby_version = '>= 1.9.2'

  s.files = (Dir.glob("*") + Dir.glob("lib/**/*")).delete_if do |item|
              item.include?("rdoc") ||
              item.include?(".git")
            end
  s.require_paths = ["lib"]
  
  s.test_files = (['.rspec'] + Dir.glob("spec/**/*")).delete_if do |item|
              item.include?("rdoc") ||
              item.include?(".git")
            end
            
  s.add_development_dependency 'rake',        '~> 10.1'
  s.add_development_dependency 'rspec',       '~> 3.0', '< 3.1'
  s.add_development_dependency 'rspec-rails', '~> 3.0', '< 3.1'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.0'
  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'fakeweb'
  
  s.add_runtime_dependency "rack",          '>= 1.4.5'
  s.add_runtime_dependency "rack-cache",    '~> 1.2'
  s.add_runtime_dependency "rack-client",   '~> 0.4.2'
  s.add_runtime_dependency "activesupport", '>= 3.2', '< 4.1'
  s.add_runtime_dependency "multi_json",    '~> 1.0'
  s.add_runtime_dependency "json",          '> 1.8.0'
  s.add_runtime_dependency "mime-types",    '> 1.1'
  s.add_runtime_dependency "i18n",          '~> 0.6', '>= 0.6.4'
  s.add_runtime_dependency "activemodel",   '>= 3.2', '< 4.1'
  s.add_runtime_dependency "active_attr",   '>= 0.8.2'
  
end
