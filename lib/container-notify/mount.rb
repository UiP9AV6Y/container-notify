require 'pathname'

module ContainerNotify
  class Mount
    attr_reader :target, :filter

    class << self
      def parse(data, default_filter = nil)
        pair = data.split(':', 2)
        target = pair[0]
        filter = pair[1] || default_filter

        new(target, filter)
      end
    end

    def initialize(target = nil, filter = nil)
      if target.is_a?(String)
        raise "Invalid mount point '#{target}'" unless File.directory?(target)
        @target = File.realpath(target)
      elsif target.is_a?(Dir)
        @target = File.realpath(target.path)
      elsif target.is_a?(Pathname)
        @target = target.realpath.to_s
      elsif target.nil?
        @target = Dir.pwd
      else
        raise "Expected a String, Dir, Pathname or nil, got '#{target}'"
      end

      if filter.is_a?(String)
        @filter = Regexp.new(filter)
      elsif filter.is_a?(Regexp)
        @filter = filter
      elsif !filter.nil?
        raise "Expected a String or Regexp, got '#{filter}'"
      end
    end
  end
end
