# frozen_string_literal: true

require_relative "test_helper"

class GemspecTest < Minitest::Test
  def test_gemspec_is_valid
    spec = Gem::Specification.load(File.expand_path("../ask-anychat.gemspec", __dir__))

    assert spec, "Could not load gemspec"
    assert_kind_of Gem::Specification, spec
    assert spec.name.to_s.start_with?("ask-")
    assert_operator spec.version.to_s, :>, "0"
  end

  # The skill travels with the gem, because a client nobody can find is a client
  # nobody uses.
  def test_the_gem_ships_its_skill
    files = Dir[File.expand_path("../lib/**/*", __dir__)].map do |path|
      path.sub("#{File.expand_path('..', __dir__)}/", "")
    end

    assert_includes files, "lib/ask/skills/anychat.use_anychat/SKILL.md"
  end
end
