module FirebugLogger #:nodoc:
  module ControllerHelpers #:nodoc:
    def self.included(base) #:nodoc:
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :assign_shortcuts, :firebug
        alias_method_chain :process_cleanup,  :firebug
        alias_method_chain :reset_session,    :firebug
        helper_method :firebug
      end
    end

    module InstanceMethods 
      def assign_shortcuts_with_firebug(request, response) #:nodoc:
        assign_shortcuts_without_firebug(request, response)
      end

      def process_cleanup_with_firebug #:nodoc:
        process_cleanup_without_firebug
      end

      def reset_session_with_firebug #:nodoc:
        reset_session_without_firebug
        remove_instance_variable(:@_firebug)
      end

      # Exposes firebug variable where logs can be submitted.
      #
      #   class UserController < ApplicationController
      #     def index
      #       firebug.debug 'Why I can be easily debugging with this thing!'
      #     end
      #   end
      def firebug 
        @_firebug = FirebugLogger::Base.new if ! defined?(@_firebug)
        @_firebug
      end
    end
  end

  module ViewHelpers
    # Used to output the logs.
    #   <%= firebug_logs %>
    #
    # Output will be repressed if the logs are empty.
    def firebug_logs
      return if ! defined?(firebug) || firebug.logs.empty?

      logs = firebug.logs.collect do |log|
        firebug_function = case log[:severity]
        when FirebugLogger::Base::DEBUG                             then 'debug'
        when FirebugLogger::Base::INFO                              then 'info'
        when FirebugLogger::Base::WARN                              then 'warn'
        when FirebugLogger::Base::ERROR, FirebugLogger::Base::FATAL then 'error'
        else                                                             'log'
        end

        # We have to add any escape characters
        log[:message].gsub!(/\\|'/) do |match|
          "\\#{match}"
        end

        "console.#{firebug_function}('#{log[:message]}');"
      end.join("\n")

      javascript_tag logs
    end
  end

  class Base
    include Logger::Severity

    attr_accessor :level, :logs

    cattr_accessor :default_severity, :instance_writer => false
    @@default_severity = DEBUG

    cattr_accessor :allowed_environments, :instance_writer => false
    @@allowed_environments = ['development']

    def initialize #:nodoc:
      @logs, @level = [], @@default_severity
    end

    # Returns +true+ if the current severity level allows for the printing of
    # +DEBUG+ messages.
    def debug?; @level <= DEBUG; end

    # Returns +true+ if the current severity level allows for the printing of
    # +INFO+ messages.
    def info?; @level <= INFO; end

    # Returns +true+ if the current severity level allows for the printing of
    # +WARN+ messages.
    def warn?; @level <= WARN; end

    # Returns +true+ if the current severity level allows for the printing of
    # +ERROR+ messages.
    def error?; @level <= ERROR; end

    alias :fatal? :error?

    # Clear the logs
    def clear
      @logs = []
    end

    # Adds a log to the FirebugLogger
    #
    # == arguments
    # * +severity+ -- indicates the severity of the log.
    # * +message+ -- log message to be logged
    # * +block+  -- optional.  Return value of the block will be the message that will be logged.
    def add(severity, message = nil, &block)
      return true unless self.class.allowed_environments.include?(RAILS_ENV)

      severity ||= UNKNOWN
      return true if severity < @level

      message = yield if message.nil? && block_given?
      @logs << {:severity => severity, :message => message}
    end

    # Log a message that is set at the default log level
    #
    # See +debug+ for more information.
    def log(message, &block)
      add(@@default_severity, message, &block)
    end

    # Log a +DEBUG+ message.
    #
    # The +block+ is ooptoinal, and if passed the return value will be the message that will be logged.
    #
    # See +debug+ for more information.
    def debug(message, &block)
      add(DEBUG, message, &block)
    end

    # Log a +INFO+ message.
    #
    # See +debug+ for more information.
    def info(message, &block)
      add(INFO, message, &block)
    end
    
    # Log a +WARN+ message.
    #
    # See +debug+ for more information.
    def warn(message, &block)
      add(WARN, message, &block)
    end

    # Log a +ERROR+ message.
    #
    # See +debug+ for more information.
    def error(message, &block)
      add(ERROR, message, &block)
    end

    alias :fatal :error

    # Log a +UNKOWN+ message.
    #
    # See +debug+ for more information.
    def unknown(message, &block)
      add(UNKOWN, &block)
    end
  end
end

ActionController::Base.send(:include, FirebugLogger::ControllerHelpers)
ActionView::Base.module_eval { include FirebugLogger::ViewHelpers }
