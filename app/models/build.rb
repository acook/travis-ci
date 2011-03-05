class Build < ActiveRecord::Base
  belongs_to :repository

  validates :repository_id, :presence => true

  class << self
    def create_from_github_payload(data)
      user       = User.find_by_login(data['repository']['owner']['name'])
      repository = user.repositories.find_or_create_by_name_and_url(data['repository']['name'], data['repository']['url'])
      commit     = data['commits'].last
      author     = commit['author'] || {}
      committer  = commit['committer'] || author || {}

      repository.builds.create(
        :commit          => commit['id'],
        :message         => commit['message'],
        :number          => repository.builds.count + 1,
        :committed_at    => commit['timestamp'],
        :committer_name  => committer['name'],
        :committer_email => committer['email'],
        :author_name     => author['name'],
        :author_email    => author['email']
      )
    end

    def started
      where(arel_table[:started_at].not_eq(nil))
    end
  end

  def append_log!(chars)
    update_attributes!(:log => [self.log, chars].join)
  end

  def finished?
    finished_at.present?
  end

  def pending?
    !finished?
  end

  def passed?
    status == 0
  end

  def color
    pending? ? '' : passed? ? 'green' : 'red'
  end

  def as_json(options = {})
    build_keys  = [:id, :number, :commit, :message, :status, :committed_at, :author_name, :author_email, :committer_name, :committer_email]
    build_keys += [:log, :started_at, :finished_at] if options[:full]
    super(:only => build_keys).merge(:repository => repository.as_json(:include_last_build => false))
  end
end
