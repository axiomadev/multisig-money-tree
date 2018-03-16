require 'simplecov'
require 'multisig-money-tree'
require 'pry'

SimpleCov.start do
  add_filter "spec"
end

def fixtures_path(name)
  File.join(File.dirname(__FILE__), 'fixtures', name)
end

def json_fixture(name)
  JSON.parse(File.read(fixtures_path("#{name}.json")), symbolize_names: true)
end