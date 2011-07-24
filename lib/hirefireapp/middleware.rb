# encoding: utf-8

module HireFireApp
  class Middleware

    ##
    # Initialize the Rack Middleware by setting the app instance
    # as well as allowing HireFire to request information via the token uri.
    #
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
      @env = env

      if test?
        [ 200, {'Content-Type' => 'text/html'}, self ]
      elsif info?
        [ 200, {'Content-Type' => 'application/json'}, self ]
      else
        @app.call(env)
      end
    end

    ##
    # Response body
    def each(&block)
      if test?
        block.call "[HireFireApp: #{ok}] Worker: #{worker} - Mapper: #{mapper}"
      elsif info?
        block.call %|{"job_count":#{job_count || 'null'}}|
      end
    end

    private

    ##
    # Counts the amount of jobs that are currently queued
    # and show be processed as soon as possible (aka the ones that are pending)
    #
    # @returns [Fixnum, nil] job_count returns nil if something went wrong
    #
    def job_count
      begin
        if defined?(Delayed::Worker)
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
    #
    def count_delayed_job
      if defined?(ActiveRecord) and Delayed::Worker.backend.to_s =~ /ActiveRecord/
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
      elsif defined?(Mongoid) and Delayed::Worker.backend.to_s =~ /Mongoid/
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
    #
    def count_resque
      Resque.info[:pending].to_i + Resque.info[:working].to_i
    end

    ##
    # Returns the name of the mapper, or "Not Found" if not found
    #
    # @returns [String]
    #
    def mapper
      if defined?(Redis) and defined?(Resque)
        "Redis"
      elsif defined?(Delayed::Worker)
        if defined?(ActiveRecord) and Delayed::Worker.backend.to_s =~ /ActiveRecord/
          "Active Record"
        elsif defined?(Mongoid) and Delayed::Worker.backend.to_s =~ /Mongoid/
          "Mongoid"
        else
          "Not Found"
        end
      else
        "Not Found"
      end
    end

    ##
    # Returns the name of the worker type, or "Not Found" if not found
    #
    # @returns [String]
    #
    def worker
      if defined?(Delayed::Job)
        "Delayed Job"
      elsif defined?(Resque)
        "Resque"
      else
        "Not Found"
      end
    end

    ##
    # Returns "OK" if both the mapper and worker were found
    #
    # @returns [String]
    #
    def ok
      if mapper =~ /Not Found/ or worker =~ /Not Found/
        "Incomplete"
      else
        "OK"
      end
    end

    ##
    # Returns true if the REQUEST_PATH matches the test url
    #
    # @returns [String]
    #
    def test?
      @env['REQUEST_PATH'] == "/hirefireapp/test"
    end

    ##
    # Returns true if the REQUEST_PATH matches the info url
    #
    # @returns [String]
    #
    def info?
      @env['REQUEST_PATH'] == "/hirefireapp/#{@token}/info"
    end

  end
end
