# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chat_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'chat_api'
  spec.version       = Dora::VERSION
  spec.authors       = ['asfarto']
  spec.email         = ['blanvam@gmail.com']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = 'Whatsapp Library for Ruby'
  spec.description   = 'Whatsapp client library for Ruby'
  spec.homepage      = 'https://github.com/asfarto/chat_api'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = %w(lib data)

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'reek', '~> 3.8.3'
end
