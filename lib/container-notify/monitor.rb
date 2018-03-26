require 'docker'
require 'listen'

module ContainerNotify
  class Monitor
    def initialize(logger, mounts, containers)
      @logger = logger
      @mounts = mounts
      @containers = containers
      @current_container = ContainerNotify::Util.current_container_id

      @listeners = []
    end

    def start(delay = 0.0, latency = 0.0, polling = false)
      raise 'No watch rules defined' unless @mounts.any?
      raise 'No notification targets defined' unless @containers.any?
      raise 'Already watching mounts' if @listeners.any?

      callback = create_notification
      default_options = {
        force_polling: polling
      }

      default_options[:wait_for_delay] = delay unless delay.zero?
      default_options[:latency] = latency unless latency.zero?

      # reduce the number of listeners by grouping all mounts
      # with the same filter criteria together
      mount_filters.each do |filter, mounts|
        targets = mounts.join(', ')
        options = {
          only: filter,
          polling_fallback_message: "Polling #{targets} for changes"
        }.merge(default_options)

        @logger.info("Adding #{targets} to watchlist")

        @listeners << Listen.to(*mounts, options, &callback)
      end

      @listeners.each(&:start)
    end

    def wait
      @logger.info('Listening to changes')
      sleep 1.0 while @listeners.any?(&:processing?)
    end

    def stop
      Listen.stop
      @listeners.clear
    end

    private

    def mount_filters
      map = {}

      @mounts.each do |mount|
        (map[mount.filter] ||= []) << mount.target
      end

      map
    end

    def create_notification
      proc do |modified, added, removed|
        if @logger.info?
          changes = [].concat(modified, added, removed).uniq.join(', ')

          @logger.info("Changed detected in #{changes}")
        end

        @containers.map(&:collect).flatten.uniq(&:id).each do |action|
          next if action.id == @current_container
          @logger.info("Forwarding #{action.method} to #{action.name}")
          action.forward
        end
      end
    end
  end
end
