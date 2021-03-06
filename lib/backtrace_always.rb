require "backtrace_always/version"

# TODO: eliminate this call from the backtrace
def BacktraceAlways
  raise ArgumentError, "block require" unless block_given?
  BacktraceAlways.enable!
  yield
ensure
  BacktraceAlways.disable!
end

module BacktraceAlways
  extend self

  TP = defined?(TracePoint) ? TracePoint.new(:raise) { |e|
                                return if e.raised_exception.is_a?(SystemExit)
                                spew(e.raised_exception)
                              } : false

  def output=(location)
    @output = location
  end

  def enable!
    return false if @enabled

    if TP
      TP.enable
    else
      __spew__ = method(:spew)
      patch(Object, :raise) do |*args|
        begin
          __og_raise__(*args)
        rescue Exception => e         # *some* people raise this
          __spew__.call(e)
          __og_raise__(e, e.to_s, e.backtrace[1..-1])
        end
      end
    end

    @enabled = true
  end

  def disable!
    return false unless @enabled

    if TP
      TP.disable
    else
      unpatch(Object, :raise)
    end

    @enabled = false
    true
  end

  def enable_inspect!
    return false if @inspect_enabled

    __bt__ = method(:build_backtrace)
    patch(Exception, :inspect) { __bt__.call(self) }

    @inspect_enabled = true
  end

  def disable_inspect!
    return false unless @inspect_enabled

    unpatch(Exception, :inspect)

    @inspect_enabled = false
    true
  end

  private

  def output
    @output
  end

  def patched_method(method)
    "__og_#{method}__"
  end

  def patch(klass, method, &block)
    patch = patched_method(method)
    klass.class_eval do
      alias_method patch, method
      define_method method, &block
    end
  end

  def unpatch(klass, method, &block)
    patch = patched_method(method)
    klass.class_eval do
      undef_method method
      alias_method method, patch
      undef_method patch
    end
  end

  def build_backtrace(e)
    message  = sprintf("%s: %s (%s)\n", e.backtrace[1], e.message, e.class)

    # This filter is *only* for calls that use BacktraceAlways(). Using it will generate
    # backtraces that include itself and the passed block's surrounding context:
    #
    #  from bs.rb:10:in `foo'							# Show this
    #  from backtrace_always/lib/backtrace_always.rb:7:in `BacktraceAlways'	# Skip this
    #  from bs.rb:10:in `foo'							# Skip this

    i  = 0
    bt = e.backtrace[2..-1]
    while i < bt.size
      if bt[i+1] =~ %r{/backtrace_always/lib/backtrace_always.rb:\d+:in\s+`BacktraceAlways'}
        i += 2
        next
      end

      message << "\tfrom #{bt[i]}\n"
      i+=1
    end

    message
  end

  def spew(e)
    out = output
    return if out.nil? && $VERBOSE.nil? # try to act like warn()

    bt = build_backtrace(e)

    out ||= $stderr
    if out.respond_to?(:debug)
      out.debug(bt)
    else
      out << bt
    end
  end
end
