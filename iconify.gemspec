# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iconify/version'

Gem::Specification.new do |spec|
  spec.name          = "iconify"
  spec.version       = Iconify::VERSION
  spec.authors       = ["Yoteichi"]
  spec.email         = ["plonk@piano.email.ne.jp"]

  spec.summary       = %q{Iconify is a utility program to turn a command line into a status icon.}
  spec.description   = %q{Iconify is a utility program to turn a command line into a status icon.}
  spec.homepage      = "https://github.com/plonk/iconifiy"
  spec.licenses      = ['GPL-2']

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "gtk2"
  spec.add_dependency "vte"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
