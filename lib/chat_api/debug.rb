require 'logger'

module Dora
  def Dora::logger
    @@logger ||= Logger.new($stderr)
  end

  # Set the logger to use for debug and warn (if enabled)
  def Dora::logger=(logger)
    @@logger = logger
  end

  # Is debugging mode enabled ?
  @@debug = false

  # Is warnings mode enabled ?
  @@warnings = false

  # Enable/disable debugging mode. When debug mode is enabled, information
  # can be logged using Dora::debuglog. When debug mode is disabled, calls
  # to Dora::debuglog are just ignored.
  def Dora::debug=(debug)
    @@debug = debug
    if @@debug
      debug_log('Debugging mode enabled.')
      #if debug is enabled, we should automatically enable warnings too
      Dora::warnings = true
    end
  end

  # Enable/disable warnings mode.
  def Dora::warnings=(warnings)
    @@warnings = warnings
    if @@warnings
      warn_log('Warnings mode enabled.')
    end
  end

  # returns true if debugging mode is enabled. If you just want to log
  # something if debugging is enabled, use Dora::debuglog instead.
  def Dora::debug
    @@debug
  end

  # Outputs a string only if debugging mode is enabled. If the string includes
  # several lines, 4 spaces are added at the beginning of each line but the
  # first one. Time is prepended to the string.
  def Dora::debug_log(string)
    return unless @@debug
    logger.debug string.chomp.gsub("\n", "\n    ")
  end

  # Outputs a string only if warnings mode is enabled.
  def Dora::warn_log(string)
    return unless @@warnings
    logger.warn string.chomp.gsub("\n", "\n    ")
  end

end