ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  DatabaseCleaner.strategy = :truncation

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def flush_redis
    Resque.redis.flushall
  rescue
    skip("Cannot connect to Redis. Omitting this test.")
  end

  class BuildableMock
    def configure; end
    def build!; end
  end

  class ConnectionMock
    def callback; end
    def errback; end
  end
end

GITHUB_PAYLOADS = {
  "gem-release" => %({
    "repository": {
      "name": "gem-release",
      "url": "http://github.com/svenfuchs/gem-release",
      "description": "Lorem ipsum dolor sit amet.",
      "homepage": "http://google.com",
      "private": false,
      "owner": {
        "name": "svenfuchs",
        "email": "svenfuchs@artweb-design.de"
      }
    },
    "commits": [{
      "id":        "9854592",
      "message":   "Bump to 0.0.15",
      "timestamp": "2010-10-27 04:32:37",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }]
  })
}

RESQUE_PAYLOADS = {
  'gem-release' => {
    'repository' => {
      'id' => 1,
      'name' => 'gem-release',
      'url' => 'http://github.com/svenfuchs/gem-release',
      'last_duration' => nil,
      'user' => { 'login' => 'svenfuchs' }
    },
    'id' => 1,
    'number' => 1,
    'commit' => '9854592',
    'message' => 'Bump to 0.0.15',
    'committer_name' => 'Sven Fuchs',
    'committer_email' => 'svenfuchs@artweb-design.de',
    'author_name' => 'Christopher Floess',
    'author_email' => 'chris@flooose.de',
    'committed_at' => '2010-10-27T04:32:37Z',
    'status' => nil
  }
}

# {'build': {"committed_at":"2011-01-11T10:33:49Z", "number":13,"repository":{"name":"svenfuchs/minimal","last_duration":null,"url":"https://github.com/svenfuchs/minimal","id":7},"commit":"5329b9b8bf206344f685359c5e60eb9f10400dc9","author_name":"Sven Fuchs","committer_name":"Sven Fuchs","id":86,"author_email":"svenfuchs@artweb-design.de","committer_email":"svenfuchs@artweb-design.de","message":"Bump to 0.0.23","status":null}}
