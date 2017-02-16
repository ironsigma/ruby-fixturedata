require 'test_helper'

class FixturedataTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Fixturedata::VERSION
  end
end
