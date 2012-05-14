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
    # Return a HTML response if the "test url" has been requested.
    # Return a JSON requested if the "info url" has been requested.
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
    # If the "test url" has been requested, we'll return information regarding the HireFire installation in HTML format.
    # If the "info url" has been regarding, we'll return the job count for the worker library (if applicable)
    # in JSON format.
    #
    def each(&block)
      if test?
        out =  "\n"
        out << "[HireFire][Web]    OK\n"
        out << "[HireFire][Worker] #{worker_ok} (Library: #{worker_library}, Mapper: #{mapper_library})\n\n"

        if worker_library =~ /Not Found/
          out << "HireFire is able to manage your web dynos, but not your worker dynos.\n"
        else
          out << "HireFire is able to manage both your web, as well as your worker dynos."
        end

        block.call out
      elsif info?
        block.call %|{"job_count":#{job_count || "null"}}|
      end
    end

    private

    ##
    # Returns the amount of queued jobs that are scheduled to be processed
    # at this time, or in the past, but not in the future.
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
        puts error
        nil
      end
    end

    ##
    # Makes Delayed::Job count the amount of currently pending jobs.
    # It'll use the ActiveRecord ORM, Mongoid ODM or MongoMapper ODM
    # depending on which is defined.
    #
    # If ActiveRecord 2 (or earlier) is being used, ActiveRecord::Relation doesn't
    # exist, and we'll have to use the old :conditions hash notation.
    #
    # @returns [Fixnum] delayed_job_count the amount of jobs currently pending
    #
    def count_delayed_job
      if defined?(ActiveRecord) and backend?(/ActiveRecord/)
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
      elsif defined?(Mongoid) and backend?(/Mongoid/)
        Delayed::Job.where(
          :failed_at  => nil,
          :run_at.lte => Time.now
        ).count
      elsif defined?(MongoMapper) and backend?(/MongoMapper/)
        Delayed::Job.where(
          :failed_at  => nil,
          :run_at.lte => Time.now
        ).count
      elsif defined?(DataMapper) and backend?(/DataMapper/)
        Delayed::Job.count(
          :failed_at  => nil,
          :run_at.lte => Time.now)
      end
    end

    ##
    # Returns the amount of jobs in the queue + the ones that are being processed
    #
    # @returns [Fixnum] resque_job_count
    #  the number of jobs pending + the amount of workers currently working
    #
    def count_resque
      Resque.info[:pending].to_i + Resque.info[:working].to_i
    end

    ##
    # Returns the name of the mapper as a string, or "Not Found" if
    # the mapper could not be found
    #
    # @returns [String]
    #
    def mapper_library
      if defined?(Redis) and defined?(Resque)
        "Redis"
      elsif defined?(Delayed::Worker)
        if defined?(ActiveRecord) and backend?(/ActiveRecord/)
          "Active Record"
        elsif defined?(Mongoid) and backend?(/Mongoid/)
          "Mongoid"
        elsif defined?(MongoMapper) and backend?(/MongoMapper/)
          "Mongo Mapper"
        else
          "Not Found"
        end
      else
        "Not Found"
      end
    end

    ##
    # Returns the name of the worker library, or "Not Found" if the worker library
    # could not be found / is not supported
    #
    # @returns [String]
    #
    def worker_library
      if defined?(Delayed::Job)
        "Delayed Job"
      elsif defined?(Resque)
        "Resque"
      else
        "Not Found"
      end
    end

    ##
    # Returns "OK" if both the mapper and worker were found, or "INCOMPLETE"
    # if either of them could not be found
    #
    # @returns [String]
    #
    def worker_ok
      if mapper_library =~ /Not Found/ or worker_library =~ /Not Found/
        "INCOMPLETE"
      else
        "OK"
      end
    end

    ##
    # Returns "true" if the mapper is used by Delayed::Job backend
    #
    # @returns [Boolean]
    #
    def backend?(mapper)
      return true if Delayed::Worker.backend.to_s =~ mapper
      false
    end

    ##
    # Returns true if the PATH_INFO matches the test url
    #
    # @returns [String]
    #
    def test?
      @env['PATH_INFO'] =~ %r{^/hirefireapp/test/?}
    end

    ##
    # Returns true if the PATH_INFO matches the info url
    #
    # @returns [String]
    #
    def info?
      @env['PATH_INFO'] =~ %r{^/hirefireapp/#{@token}/info/?}
    end

  end
end
