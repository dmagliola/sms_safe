require "rubygems"

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
end

require "coveralls"
Coveralls.wear!

require "minitest/autorun"
require "minitest/reporters"
MiniTest::Reporters.use!

require "shoulda"
require "shoulda-context"
require "shoulda-matchers"

# Make the code to be tested easy to load.
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
