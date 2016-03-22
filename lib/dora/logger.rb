require 'logger'

module Dora
  module Logging
    # Logger pool, acquire logger from the logger table or not, create a new logger
    #
    # @return [Logger] Logger instance
    # @api private
    def logger
      @logger ||= configure_logger
    end

    # Set the logger to use for debug and warn (if enabled)
    #
    # @param [String] logger logger object
    # @return [Logger] Logger instance
    # @api private
    def logger=(logger)
      @logger = logger
    end

    # Is debugging mode enabled ?
    @@enable_debug = false

    # Is warnings mode enabled ?
    @@enable_warning = false

    # returns true if debugging mode is enabled. If you just want to log
    # something if debugging is enabled, use debug_log instead.
    #
    # @return [Bool] true / false
    def enabled?
      @@enable_debug
    end

    # returns true if warning mode is enabled. If you just want to log
    # something if warning is enabled, use warn_log instead.
    #
    # @return [Bool] true / false
    def warning_enabled?
      @@enable_warning
    end

    # Enable debugging mode. When debug mode is enabled, information can be logged using debug_log.
    # When debug mode is disabled, calls to debug_log are just ignored.
    #
    # @api private
    def enable_debug
      @@enable_debug = true
      debug_log('Debugging mode enabled.')
      #if debug is enabled, we should automatically enable warnings too
      @@enable_warning = true
    end

    # Disable debugging mode.
    #
    # @api private
    def disable_debug
      debug_log('Debugging mode disabled.')
      @@enable_debug = false
      @@enable_warning = false
    end

    # Enable warnings mode.
    #
    # @api private
    def enable_warning
      @@enable_warning = true
      warn_log('Warnings mode enabled.')
    end

    class Logger < ::Logger
      # Outputs a string only if debugging mode is enabled. If the string includes several lines,
      # 4 spaces are added at the beginning of each line but the first one. Time is prepended to the string.
      def debug_log(string)
        return unless @@enable_debug
        logger.debug string.chomp.gsub("\n", "\n    ")
      end

      # Outputs a string only if warnings mode is enabled.
      def warn_log(string)
        return unless @@enable_warning
        logger.warn string.chomp.gsub("\n", "\n    ")
      end
    end

    private

    # Create a new logger
    #
    # @return [Logger] Logger instance
    # @api private
    def configure_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        blanks = severity.size == 4 ? '  ' : ' '
        "[#{date_format}] #{severity}#{blanks}(#{progname}): #{msg}\n"
      end

      logger
    end
  end
end