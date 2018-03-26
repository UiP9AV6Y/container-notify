[microbadger]: https://microbadger.com/images/uip9av6y/container-notify
[Docker library]: https://store.docker.com/images/alpine
[MIT License]: https://opensource.org/licenses/MIT
[Listen]: https://github.com/guard/listen
[Docker]: https://github.com/swipely/docker-api

# container-notify

Signal docker containers upon filesystem changes.
Reacts to changes in the filesystem either via kernel events
or by polling in regular intervals. Containers can either
be restarted or sent a signal.
Suitable for deployment with docker-compose or just docker.

Simply said, this project acts as glue between the
filesystem (using the [Listen][] Gem) and Docker (using
the [Docker][]-API Gem)

Containers will be queried with every change. Containers
started after the monitor will still be notified if they
satisfy the query criteria.

[![](https://images.microbadger.com/badges/image/uip9av6y/container-notify.svg)][microbadger]
[![](https://images.microbadger.com/badges/version/uip9av6y/container-notify.svg)][microbadger]
[![](https://images.microbadger.com/badges/commit/uip9av6y/container-notify.svg)][microbadger]

## Usage

Instructions can either be given via commandline arguments
or environment variables.

`docker run -d --name my-container-notify
  --mount type=volume,source=examples,destination=/watch
  --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock
  --env NOTIFY_LATENCY=60
  container-notify:latest
  --watch=/watch`

| Option | Type | Description | Default Value |
| ------ | ---- | ----------- | ------------- |
| -f, --filter PATTERN | Regex | React only to file changes matching the given pattern | All files trigger notifications, exceptions apply \* |
| -a, --action ACTION | String | Signal/Action to perform | HUP |
| -d, --delay SECONDS | Float | Time to wait before dispatching notifications | \*\* |
| -l, --latency SECONDS | Float | Time between checking for changes | \*\* |
| -v, --[no-]verbose | Bool | Change verbosity for reports about state changes and performed actions | - |
| -c, --compose [PROJECT] | String | Notify containers based on the docker-compose service label value instead of their name | The same project as the container \*\*\* |
| -p, --[no-]polling | Poll filesystem for changes instead of listening to events | Bool | - |
| -N, --notify CONTAINER | String | Container (name) to notify upon changes | All containers sharing the same mounts as the current container |
| -W, --watch TARGET | Directory | Mount (directory) to watch for changes | All mounts of the current container |

\* The [Listen][] ignores certain files automatically, such
as VCS metadata

\*\* Uses the [Listen][] default values, which are different
if polling is enabled

\*\*\* Using '.' will reduce the search to containers of the
same compose project, using '\*', will search for every
container with the *com.docker.compose.service* label.

| Environment variable | Commandline equivalent |
| -------------------- | ---------------------- |
| NOTIFY_DELAY | -d |
| NOTIFY_LATENCY | -l |
| CONTAINER_ACTION | -a |
| MOUNT_FILE_FILTER | -f |
| COMPOSE_PROJECT | -c |
| FORCE_POLLING \* | -p |
| LOG_VERBOSITY | -v |

\* The mere existence of this variable results in the
activation of this behaviour

## Image setup

the image is based on the **Alpine Linux** image from
the [Docker library][].

## Development

Docker-Compose is used to create an encapsulated development
environment. After checking out the repo, run
`docker-compose run --rm monitor sh` to enter the container.
Then, run `bundle exec rake spec` to run the tests.
The main application can be run with `./bin/container-notify`.

The source code from the host is mounted into the container
and any change is reflected immediately; you most likely need
to stop the application if running (Ctrl+C) and start it
again.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/uip9av6y/container-notify.

## License

The gem is available as open source under the terms of the [MIT License][].

The Docker image also contain other software which may be
under other licenses (such as Bash, etc from the base
distribution, along with any direct or indirect
dependencies of the primary software being contained).
It is the image user's responsibility to ensure that any use
of this image complies with any relevant licenses for all
software contained within.
