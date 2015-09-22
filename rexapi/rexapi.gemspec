# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rexcore'
require 'rexapi/version'

Gem::Specification.new do |spec|
  spec.name          = "rexapi"
  spec.version       = RexAPI::VERSION
  spec.authors       = ["Bob Ashforth"]
  spec.email         = ["rashforth@marketo.com"]
  spec.summary       = %q{Rexecute is a complete framework for remote execution of complex tasks in a linux network.}
  spec.description   = %q{Rexecute executes remote tasks with no client required on the target machine, and tracks all execution in its server.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 0"
  spec.add_runtime_dependency "rexcore", '~> 0.0', '~> 0.1.1'
end
