# encoding: utf-8

module HireFireApp
  class Middleware

    ##
    # Initialize the Rack Middleware by setting the app instance
    # as well as allowing HireFire to request information via the token uri.
    def initialize(app)
      @app   = app
      @token = ENV['HIREFIREAPP_TOKEN']
    end

    ##
    # If we are currently in the Heroku environment, and the path to the HireFire info uri
    # has been requested (and the token belongs to the app) then we'll calculate the amount of
    # jobs that are currently pending (either Delayed Job with Active Record / Mongoid or Resque with Redis).
    #
    # Once the job_count has been determined, we build a simple JSON string object and
    # create a rack-based json response with 200 status. This will be returned to the HireFire service
    # in order to determine what actions to take in terms of scaling up or down.
    def call(env)
      if env['REQUEST_PATH'] == "/hirefireapp/#{@token}/info.json"
        [ 200, {'Content-Type' => 'application/json'},  %|{"job_count":#{job_count || 'null'}}| ]
      else
        @app.call(env)
      end
    end

   private

   ##
   # Counts the amount of jobs that are currently queued
   # and show be processed as soon as possible (aka the ones that are pending)
   #
   # @returns [Fixnum, nil] job_count returns nil if something went wrong
    def job_count
      begin
        if defined?(Delayed::Job)
          count_delayed_job
        elsif defined?(Resque)
          count_resque
        end
      rescue => error
        nil
      end
    end

    ##
    # Makes Delayed::Job count the amount of currently pending jobs.
    # It'll use the ActiveRecord ORM, or the Mongoid ODM depending on
    # which of them is defined.
    #
    # If ActiveRecord 2 (or earlier) is being used, ActiveRecord::Relation doesn't
    # exist, and we'll have to use the old :conditions hash notation.
    #
    # @returns [Fixnum] delayed_job_count the amount of jobs currently pending
    def count_delayed_job
      if defined?(ActiveRecord)
        if defined?(ActiveRecord::Relation)
          Delayed::Job.
          where(:failed_at => nil).
          where('run_at <= ?', Time.now).count
        else
          Delayed::Job.all(
            :conditions => [
              'failed_at IS NULL and run_at <= ?', Time.now.utc
            ]
          ).count
        end
      elsif defined?(Mongoid)
        Delayed::Job.where(
          :failed_at  => nil,
          :run_at.lte => Time.now
        ).count
      end
    end

    ##
    # Makes Resque count the amount of currently pending jobs.
    #
    # @returns [Fixnum] resque_job_count
    #  the number of jobs pending + the amount of workers currently working
    def count_resque
      Resque.info[:pending].to_i + Resque.info[:working].to_i
    end

  end
end
