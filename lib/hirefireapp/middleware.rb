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
    # Simple router. If a request come in at the "test" url (the url to test if HireFire is properly installed)
    # then we return information about the current environment (orm, odm, kvs, worker library, etc). Returns "Not Found"
    # and specified "what wasn't found" in case the environment isn't complete (e.g. the worker library could not be found).
    #
    # HireFireApp.com will always ping to the "info?" url. This will return JSON format containing the current job queue
    # for the given worker library
    #
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
    # Response body - This is the data that gets returned to the requester
    # depending on which URL was requested.
    #
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
    # Returns true if the PATH_INFO matches the test url
    #
    # @returns [String]
    #
    def test?
      @env['PATH_INFO'] == "/hirefireapp/test"
    end

    ##
    # Returns true if the PATH_INFO matches the info url
    #
    # @returns [String]
    #
    def info?
      @env['PATH_INFO'] == "/hirefireapp/#{@token}/info"
    end

  end
end
