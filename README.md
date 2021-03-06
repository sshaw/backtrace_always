# BacktraceAlways

[![Build Status](https://travis-ci.org/sshaw/backtrace_always.svg?branch=master)](https://travis-ci.org/sshaw/backtrace_always)

Always print the message, class, and backtrace when an exception is raised

## Overview

```ruby
require "backtrace_always"

def foo
  bar
end

def bar
  baz
end

def baz
  begin
	raise "some error brah brah"
  rescue => e
	puts "caught: #{e}"
  end
end

BacktraceAlways.enable!

foo  # backtrace to $stderr

BacktraceAlways.disable!

foo  # no backtrace to $stderr

BacktraceAlways { foo }  # within the block, backtrace to $stderr

BacktraceAlways.enable_inspect!

def div(n)
  10/n
end

begin
  div(0)
rescue => e
  p e  # prints the backtrace
end

BacktraceAlways.disable_inspect!

io = File.open("out.log", "w")
BacktraceAlways.output = io
BacktraceAlways { foo } # backtrace to io
io.close

BacktraceAlways.output = logger  # Will log at debug level
```

## Installation

Bundler

```ruby
gem "backtrace_always"
```

RubyGems

```
gem install backtrace_always
```

## Backtrace Printing

If `TracePoint` is available (Ruby >= 2 in most cases) all exceptions will have their backtrace printed
(yes, even `Exception` sub classes).

If `TracePoint` is not available `raise` is overridden, and only **explicit calls to it** will print the backtrace.
In this case exceptions raised by the Ruby interpreter will not have their backtrace printed.

By default `BacktraceAlways` acts like `warn` and will output to `$stderr` only if warnings are enabled.
This can be changed by setting `BacktraceAlways.output` to the `IO` instance of your choosing.

## Why?

To ease the pain of tracking down bugs in bad codebases.

## Author

Skye Shaw [skye.shaw {AT} gmail.com]

## License

Copyright (c) 2015 Skye Shaw. Released under the MIT License.
