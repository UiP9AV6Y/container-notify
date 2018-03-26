require 'optparse'
require 'docker'
require 'logger'

require 'container-notify/monitor'
require 'container-notify/container'
require 'container-notify/mount'
require 'container-notify/util'

module ContainerNotify
  class Bin
    VERBOSITY_LEVELS = [
      Logger::WARN,
      Logger::INFO,
      Logger::DEBUG
    ].freeze
    ANY_PROJECT = '*'.freeze
    CURRENT_PROJECT = '.'.freeze

    def initialize(args = [], env = {})
      @args = args
      @containers = []
      @mounts = []
      @delay = env['NOTIFY_DELAY'].to_f
      @latency = env['NOTIFY_LATENCY'].to_f
      @action = env['CONTAINER_ACTION']
      @filter = env['MOUNT_FILE_FILTER']
      @compose = env['COMPOSE_PROJECT']
      @polling = env.key?('FORCE_POLLING')
      @verbosity = env['LOG_VERBOSITY'].to_i
      @logger = ::Logger.new(STDOUT)

      formatter = proc { |_, _, _, msg| "#{msg}\n" }

      Listen.logger = Docker.logger = Logger.new(STDERR)

      Listen.logger.formatter = Docker.logger.formatter = @logger.formatter = formatter
    end

    def run
      mounts = []
      containers = []

      begin
        parser("Usage: #{$PROGRAM_NAME} [options]").parse!(@args)
        Listen.logger.level = Docker.logger.level = @logger.level = log_level
        bootstrap_docker_client

        mounts = find_mounts
        containers = find_containers
      rescue StandardError => e
        STDERR.puts e
        return 1
      end

      monitor = ContainerNotify::Monitor.new(@logger, mounts, containers)

      begin
        monitor.start(@delay, @latency, @polling)
        monitor.wait
      rescue StandardError => e
        monitor.stop

        STDERR.puts e
        return 1
      end

      0
    end

    def log_level
      return VERBOSITY_LEVELS[0] if @verbosity < 0
      return VERBOSITY_LEVELS[-1] if @verbosity >= VERBOSITY_LEVELS.length

      VERBOSITY_LEVELS[@verbosity]
    end

    private

    def find_mounts
      return find_mounts_by_config if @mounts.any?

      find_mounts_from_current_container
    end

    def find_mounts_by_config
      @mounts.map do |mount|
        ContainerNotify::Mount.parse(mount, @filter)
      end
    end

    def find_mounts_from_current_container
      cont = ContainerNotify::Util.current_container

      raise 'Unable to detect mounts from current container' if cont.nil?

      @logger.info('Watching mounts from current container')
      cont.info['Mounts'].map do |mount|
        next unless File.directory?(mount['Destination'])
        query = mount['Destination']
        @logger.debug("Watching #{query}")
        ContainerNotify::Mount.parse(query, @filter)
      end.compact
    end

    def find_containers
      return find_containers_by_config if @containers.any?

      find_containers_from_current_mounts
    end

    def find_containers_by_config
      if @compose.nil?
        query_service = false
        project = nil
      elsif @compose == CURRENT_PROJECT
        cont = ContainerNotify::Util.current_container

        raise 'Unable to detect containers by common mounts' if cont.nil?

        query_service = true
        project = cont.info['Config']['Labels']['com.docker.compose.project']
      elsif @compose == ANY_PROJECT
        query_service = true
        project = nil
      else
        query_service = true
        project = @compose
      end

      @containers.map do |container|
        ContainerNotify::Container.parse(container, @action, query_service, project)
      end
    end

    def find_containers_from_current_mounts
      cont = ContainerNotify::Util.current_container

      raise 'Unable to detect containers by common mounts' if cont.nil?

      @logger.info('Notifying containers based on their mounts')

      cont.info['Mounts'].map do |mount|
        next unless File.directory?(mount['Destination'])
        # volume or bind mount
        query = mount['Name'] || mount['Source']
        @logger.debug("Notifying containers with mount #{query}")
        ContainerNotify::Container.by_mount(query, @action)
      end.compact
    end

    def bootstrap_docker_client
      if @mounts.empty? || @containers.empty?
        # https://github.com/swipely/docker-api/issues/441
        Docker.send(:remove_const, 'API_VERSION')
        # the Mounts information was added with v1.20
        Docker.const_set('API_VERSION', '1.20')
      end

      Docker.validate_version!
    end

    def parser(banner)
      OptionParser.new do |o|
        actions = ContainerNotify::Container.action_symbols

        o.banner = banner
        o.version = ContainerNotify::VERSION

        o.on('-f', '--filter PATTERN',
             'React only to file changes matching the given pattern') do |p|
          @filter = p
        end

        o.on('-a', '--action ACTION', actions,
             "Action to perform upon changes (#{actions.join(', ')})") do |a|
          @action = a
        end

        o.on('-d', '--delay SECONDS', Float,
             'Time to wait before dispatching notifications') do |s|
          @delay = s
        end

        o.on('-l', '--latency SECONDS', Float,
             'Time between checking for changes. ' \
             'If polling is enabled, this is ' \
             'essentially the poll interval') do |s|
          @latency = s
        end

        o.on('-v', '--[no-]verbose',
             'Change verbosity for reports about state changes ' \
             'and performed actions. Can be used multiple times' \
             'to increase the verbosity.') do |v|
          change = v ? 1 : -1
          @verbosity += change
        end

        o.on('-c', '--compose [PROJECT]',
             'Notify containers based on the docker-compose service ' \
             'label value instead of their name. If no project is provided ' \
             'the project from the current container is used as reference. ' \
             'Use * to extend the search to all projects ' \
             'on the current host and . to limit it to the current project ' \
             '(this assumes, this script is running in a compose stack)') do |p|
          @compose = p || CURRENT_PROJECT
        end

        o.on('-p', '--[no-]polling',
             'Poll filesystem for changes ' \
             'instead of listening to events') do |p|
          @polling = p
        end

        o.on('-N', '--notify CONTAINER',
             'Container (name) to notify upon changes') do |c|
          @containers << c
        end

        o.on('-W', '--watch TARGET',
             'Mount (directory) to watch for changes') do |t|
          @mounts << t
        end
      end
    end
  end
end
