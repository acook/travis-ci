require 'uri'

class Repository < ActiveRecord::Base
  has_many :builds, :dependent => :delete_all
  has_one :last_build,          :class_name => 'Build', :order => 'started_at DESC'
  has_one :last_finished_build, :class_name => 'Build', :order => 'started_at DESC', :conditions => 'finished_at IS NOT NULL'
  has_one :last_success,        :class_name => 'Build', :order => 'started_at DESC', :conditions => { :status => 0 }
  has_one :last_failure,        :class_name => 'Build', :order => 'started_at DESC', :conditions => { :status => 1 }
  belongs_to :user

  validates :user_id, :presence => true
  validates :url, :presence => true, :uniqueness => true

  REPOSITORY_ATTRS = [:id, :name, :url, :last_duration]
  LAST_BUILD_ATTRS = [:id, :number, :commit, :message, :status, :log, :started_at, :finished_at, :author_name, :author_email, :committer_name, :committer_email]
  USER_ATTRS       = [:login]

  class << self
    def timeline
      # should probably denormalize the last build attributes which are relevant to the timeline at some point
      includes(:last_build).where(Build.arel_table[:started_at].not_eq(nil)).order(Build.arel_table[:started_at].desc)
    end

    def recent
      limit(60)
    end

    def human_status_by_name(name)
      repository = find_by_name(name)
      return 'unknown' unless repository && repository.last_finished_build
      repository.last_finished_build.status == 0 ? 'stable' : 'unstable'
    end
  end

  def as_json(options = {})
    options ||= {} # ActiveSupport seems to pass nil here?
    include_last_build = options.key?(:include_last_build) ? options[:include_last_build] : true
    include_attrs = { :user => { :only => USER_ATTRS } }
    include_attrs.update( :last_build => { :only => LAST_BUILD_ATTRS }) if include_last_build
    super(:only => REPOSITORY_ATTRS, :include => include_attrs)
  end
end
