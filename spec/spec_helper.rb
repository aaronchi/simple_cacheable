$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rails'
require 'active_record'
require 'rspec'
require 'mocha'

require 'cacheable'

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }

class TestCache
  attr_reader :data

  def initialize
    @data = {}
  end

  def fetch(key, &block)
    if read(key)
      read(key)
    else
      write(key, block.call)
    end
  end

  def read(key)
    @data[key]
  end

  def write(key, value)
    @data[key] = value
  end

  def delete(key)
    @data.delete key
  end

  def clear
    @data.clear
  end
end

module Rails
  class <<self
    def cache
      @cache ||= TestCache.new
    end
  end
end

RSpec.configure do |config|
  config.mock_with :mocha

  config.before :all do
    ::ActiveRecord::Schema.define(:version => 1) do
      create_table :users do |t|
        t.string :login
      end

      create_table :accounts do |t|
        t.integer :user_id
      end

      create_table :posts do |t|
        t.integer :user_id
        t.string :title
      end

      create_table :comments do |t|
        t.integer :commentable_id
        t.string :commentable_type
      end
    end
  end

  config.after :all do
    ::ActiveRecord::Base.connection.tables.each do |table|
      ::ActiveRecord::Base.connection.drop_table(table)
    end
  end
end
