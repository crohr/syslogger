## Syslogger

[![GitHub license](https://img.shields.io/github/license/crohr/syslogger.svg)](https://github.com/crohr/syslogger/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/crohr/syslogger.svg)](https://github.com/crohr/syslogger/releases/latest)
[![Gem](https://img.shields.io/gem/v/syslogger.svg)](https://rubygems.org/gems/syslogger)
[![Gem](https://img.shields.io/gem/dtv/syslogger.svg)](https://rubygems.org/gems/syslogger)
[![CI](https://github.com/crohr/syslogger/workflows/CI/badge.svg)](https://github.com/crohr/syslogger/actions)

A drop-in replacement for the standard Logger Ruby library, that logs to the syslog instead of a log file.
Contrary to the SyslogLogger library, you can specify the facility and the syslog options.

## Installation

```sh
$ gem install syslogger
```

## Usage

```ruby
require 'syslogger'

# Will send all messages to the local0 facility, adding the process id in the message
logger = Syslogger.new("app_name", Syslog::LOG_PID, Syslog::LOG_LOCAL0)

# Optionally split messages to the specified number of bytes
logger.max_octets = 480

# Send messages that are at least of the Logger::INFO level
logger.level = Logger::INFO # use Logger levels

logger.debug "will not appear"
logger.info "will appear"
logger.warn "will appear"
```

## Contributions

See <https://github.com/crohr/syslogger/contributors>.

## Copyright

Copyright (c) 2010 Cyril Rohr, INRIA Rennes-Bretagne Atlantique. See LICENSE for details.
