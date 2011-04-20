require 'logger'

log = Logger.new(STDOUT)
log.level = Logger::DEBUG

log.debug("Created logger")
log.info("Program started")
log.warn("Nothing to do!")


