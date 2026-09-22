# frozen_string_literal: true

require_relative "lib/ask/anychat/version"

Gem::Specification.new do |spec|
  spec.name = "ask-anychat"
  spec.version = Ask::AnyChat::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "Anychat API client for the ask-rb ecosystem"
  spec.description = "Creates and manages the agents an Anychat workspace owns. " \
                     "Anychat gives a business an agent of its own — a page customers " \
                     "can visit, a chat they can talk to, and the words it answers " \
                     "with. This is the client layer only: the tool framing that " \
                     "exposes it to an agent (MCP servers, native Ask::Tools) is " \
                     "provided by the consumers."

  spec.homepage = "https://github.com/ask-rb/ask-anychat"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ask-auth", ">= 0.3.5"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
