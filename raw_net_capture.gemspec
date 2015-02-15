Gem::Specification.new "raw_net_capture", '1.1.0' do |gem|
  gem.authors       = ["Gary Grossman", "Victor Kmita"]
  gem.email         = ["ggrossman@zendesk.com", "vkmita@zendesk.com"]
  gem.description   = "Adds raw capture capability to Ruby's net debug_output"
  gem.summary       = "Capture raw data in net debug_output"
  gem.homepage      = "https://github.com/zendesk/raw_net_capture"
  gem.license       = "Apache License Version 2.0"
  gem.files         = `git ls-files lib`.split($\)
  gem.add_development_dependency('appraisal')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('bundler')
end
