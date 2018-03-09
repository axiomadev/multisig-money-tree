# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multisig-money-tree/version'

Gem::Specification.new do |spec|
  spec.name          = "multisig-money-tree"
  spec.version       = MultisigMoneyTree::VERSION
  spec.authors       = ["Aleksandr Korol"]
  spec.email         = ["korol.sas@gmail.com"]
  spec.description   = %q{A Ruby Gem implementation of Bitcoin BIP-45}
  spec.summary       = %q{(Bitcoin standard BIP0045)}
  spec.homepage      = ""
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://localhost"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir['**/*'].reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi"
  spec.add_dependency "bitcoin-ruby"
  
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency 'byebug', '~> 9.1'
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "pry"
end
