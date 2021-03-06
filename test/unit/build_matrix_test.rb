require 'test_helper_rails'

class BuildTest < ActiveSupport::TestCase
  Build.send(:public, :expand_matrix!, :matrix_config, :expand_matrix_config)

  attr_reader :config

  def setup
    super
    @config = YAML.load <<-yaml
      rvm:
        - 1.8.7
        - 1.9.2
      gemfile:
        - gemfiles/rails-2.3.x
        - gemfiles/rails-3.0.x
    yaml
  end

  test 'matrix_config w/ no array values' do
    build = Factory(:build, :config => { 'rvm' => '1.8.7', 'gemfile' => 'gemfiles/rails-2.3.x', 'env' => 'FOO=bar' })
    assert_nil build.matrix_config
  end

  test 'matrix_config w/ just array values' do
    build = Factory(:build, :config => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['gemfiles/rails-2.3.x', 'gemfiles/rails-3.0.x'] })
    expected = [
      [["rvm", "1.8.7"], ["rvm", "1.9.2"]],
      [["gemfile", "gemfiles/rails-2.3.x"], ["gemfile", "gemfiles/rails-3.0.x"]]
    ]
    assert_equal expected, build.matrix_config
  end

  test 'matrix_config w/ unjust array values' do
    build = Factory(:build, :config => { 'rvm' => ['1.8.7', '1.9.2', 'ree'], 'gemfile' => ['gemfiles/rails-3.0.x'], 'env' => ['FOO=bar', 'FOO=baz'] })
    expected = [
      [["rvm", "1.8.7"], ["rvm", "1.9.2"], ["rvm", "ree"]],
      [["gemfile", "gemfiles/rails-3.0.x"], ["gemfile", "gemfiles/rails-3.0.x"], ["gemfile", "gemfiles/rails-3.0.x"]],
      [["env", "FOO=bar"], ["env", "FOO=baz"], ["env", "FOO=baz"]]
    ]
    assert_equal expected, build.matrix_config
  end

  test 'matrix_config w/ an array value and a non-array value' do
    build = Factory(:build, :config => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => 'gemfiles/rails-2.3.x' })
    expected = [
      [["rvm", "1.8.7"], ["rvm", "1.9.2"]],
      [["gemfile", "gemfiles/rails-2.3.x"], ["gemfile", "gemfiles/rails-2.3.x"]]
    ]
    assert_equal expected, build.matrix_config
  end

  test 'expanding the build matrix configuration' do
    build = Factory(:build, :config => config)
    expected = [
      [['rvm', '1.8.7'], ['gemfile', 'gemfiles/rails-2.3.x']],
      [['rvm', '1.8.7'], ['gemfile', 'gemfiles/rails-3.0.x']],
      [['rvm', '1.9.2'], ['gemfile', 'gemfiles/rails-2.3.x']],
      [['rvm', '1.9.2'], ['gemfile', 'gemfiles/rails-3.0.x']]
    ]
    assert_equal expected, build.expand_matrix_config(build.matrix_config.to_a)
  end

  test 'expanding a matrix build sets the config to the children' do
    build = Factory(:build, :config => config)
    expected = [
      { 'rvm' => '1.8.7', 'gemfile' => 'gemfiles/rails-2.3.x' },
      { 'rvm' => '1.8.7', 'gemfile' => 'gemfiles/rails-3.0.x' },
      { 'rvm' => '1.9.2', 'gemfile' => 'gemfiles/rails-2.3.x' },
      { 'rvm' => '1.9.2', 'gemfile' => 'gemfiles/rails-3.0.x' }
    ]
    assert_equal expected, build.matrix.map(&:config)
  end

  test 'expanding a matrix build copies the build attributes' do
    build = Factory(:build, :commit => '12345', :config => config)
    assert_equal ['12345'] * 4, build.matrix.map(&:commit)
  end

  test 'expanding a matrix build adds a sub-build number to the build number' do
    build = Factory(:build, :number => '2', :config => config)
    assert_equal ['2.1', '2.2', '2.3', '2.4'], build.matrix.map(&:number)
  end

  test 'matrix_expanded? returns true if the matrix has just been expanded' do
    assert Factory(:build, :config => config).matrix_expanded?
  end

  test 'matrix_expanded? returns false if there is no matrix' do
    assert !Factory(:build).matrix_expanded?
  end

  test 'matrix_expanded? returns false if the matrix existed before' do
    build = Factory(:build, :config => config)
    build.save!
    assert !build.matrix_expanded?
  end

  test 'matrix build as_json' do
    build = Factory(:build, :number => '2', :commit => '12345', :config => config)
    attributes = {
      'parent_id' => build.id,
      'committed_at' => nil,
      'commit' => '12345',
      'author_name' => nil,
      'author_email' => nil,
      'committer_name' => nil,
      'committer_email' => nil,
      :repository => {
        'id' => build.repository.id,
        'name' => 'svenfuchs/minimal',
        'last_duration' => 60,
        'url' => 'http://github.com/svenfuchs/minimal',
      },
      'message' => nil,
      'status' => nil,
      'config' => {
        'gemfile' => 'gemfiles/Gemfile.rails-2.3.x',
        'rvm' => '1.8.7'
      }
    }
    expected = {
      'id' => build.id,
      'parent_id' => nil,
      'number' => '2',
      'commit' => '12345',
      'message' => nil,
      'status' => nil,
      'committed_at' => nil,
      'committer_name' => nil,
      'committer_email' => nil,
      'author_name' => nil,
      'author_email' => nil,
      'config' => { 'gemfile' => ['gemfiles/rails-2.3.x', 'gemfiles/rails-3.0.x'], 'rvm' => ['1.8.7', '1.9.2'] },
      :repository => {
        'id' => build.repository.id,
        'name' => 'svenfuchs/minimal',
        'url' => 'http://github.com/svenfuchs/minimal',
        'last_duration' => 60,
      },
      :matrix => [
        attributes.merge('id' => build.id + 1, 'number' => '2.1', 'config' => { 'gemfile' => 'gemfiles/rails-2.3.x', 'rvm' => '1.8.7' }),
        attributes.merge('id' => build.id + 2, 'number' => '2.2', 'config' => { 'gemfile' => 'gemfiles/rails-3.0.x', 'rvm' => '1.8.7' }),
        attributes.merge('id' => build.id + 3, 'number' => '2.3', 'config' => { 'gemfile' => 'gemfiles/rails-2.3.x', 'rvm' => '1.9.2' }),
        attributes.merge('id' => build.id + 4, 'number' => '2.4', 'config' => { 'gemfile' => 'gemfiles/rails-3.0.x', 'rvm' => '1.9.2' }),
      ]
    }
    assert_equal_hashes expected, build.as_json
  end
end
