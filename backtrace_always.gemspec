# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'backtrace_always/version'

Gem::Specification.new do |spec|
  spec.name          = "backtrace_always"
  spec.version       = BacktraceAlways::VERSION
  spec.authors       = ["Skye Shaw"]
  spec.email         = ["skye.shaw@gmail.com"]
  spec.summary       = %q{Always print the message, class, and backtrace when an exception is raised}
  #spec.description   = %q{}
  spec.homepage      = "https://github.com/sshaw/backtrace_always"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
