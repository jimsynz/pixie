# Pixie

[![Codeship](https://img.shields.io/codeship/eb1dde70-2d10-0133-c122-16954c8f6a18/master.svg)](https://codeship.com/projects/98754)
[![Hex.pm](https://img.shields.io/hexpm/v/espec.svg)](https://hex.pm/packages/pixie)


## Pixie is a [Faye](http://faye.jcoglan.com) compatible Bayeux implementation

Pixie is inspired by [Faye](http://faye.jcoglan.com/) and was originally
planned as a port, but has diverged significantly as I've learned the Erlang
way of modelling these sorts of problems.

# Heroku Add-on

If you're planning on running Faye on Heroku you're probably going to have a
bad time.  Take a look at [MessageRocket](https://messagerocket.co/) as an
alternative, and help support the author to maintain more great open source
projects.

## License

Pixie is Copyright (c) 2015 James Harton and licensed under the terms of
the MIT Public License (see the LICENSE file included with this distribution
for more details).

## Installation

Add `pixie` to your dependencies in the `mix.exs` file:

```elixir
def deps do
  # ...
  {:pixie, "~> 0.1.3"}
  # ...
end
```

Also to the `application` section of your `mix.exs` file:

```elixir
def application do
  [
    applications: [
      # ...
      :pixie,
      # ...
    ]
  ]
end
```

Then use `mix deps.get` to download Pixie from [hex](https://hex.pm/).

## Status

Pixie is still pre 1.0, however it works and is compatible with the
popular [Faye](http://faye.jcoglan.com/) JavaScript and Ruby clients.

Pixie is used in production at [MessageRocket](https://messagerocket.co/) to
handle relatively large message loads.  Development is mostly guided by the
needs of MessageRocket, however pull requests and issues are gratefully
received.

## Features

  - Compatible with Faye JavaScript and Ruby clients.
  - Supports both in-memory (ETS) and clustered (Redis) backends.
  - Handles all Bayeux message types.
  - Handles all Bayeux features except service channels.
  - Handles the following connection types:
      - long-polling
      - cross-origin-long-polling
      - callback-polling
      - websocket

## Usage

Once you have pixie installed in your project you can run a stand alone-server
with `mix pixie.server`.

### Configuration

The configuration options and their defaults are shown here:

```elixir
# This is the default backend configuration, you don't need to set it.
config :pixie, :backend,
  name: :ETS

# If you want to use Redis for clustering. The Redis backend defaults to
# localhost, unless you specify it here.
config :pixie, :backend,
  name: :Redis,
  redis_url: "redis://localhost:6379"

# When clients subscribe to channels we don't have to respond immediately, and
# can instead wait until there is a message to be sent on that channel or a
# heartbeat timeout expires, whichever happens first.
# Setting this option to true means that subscriptions are responded to
# which *may* increase time to first message for those not using websockets.
config :pixie, :subscribe_immediately, false

# Add extensions to be loaded at startup:
config :pixie, :extensions, [My.Extension.Module.Name]

# Add monitors to be loaded at startup:
config :pixie, :monitors, [
  My.Monitor.Module.Name,
  # ... or ...
  {My.Monitor.Module.Name, [some_arg]}
]

# Explicitly configure transports available to clients:
config :pixie, :enabled_transports, ~w| long-polling cross-origin-long-polling callback-polling websocket |
```

### Using with Phoenix

You can add Pixie as a custom dispatcher rule for Phoenix with Cowboy by adding
the following to your application configuration:

```elixir
config :myapp, MyApp.Endpoint,
  http: [
    dispatch: [
      {:_, [
        {"/pixie", Pixie.Adapter.Cowboy.HttpHandler, {Pixie.Adapter.Plug, []}},
        {:_,       Plug.Adapters.Cowboy.Handler,     {MyApp.Endpoint, []}}
      ]}
    ]
  ]
```

Obviously, you can change `"/pixie"` to any path you wish.

### Sending messages from the server

You can publish messages from within the server using `Pixie.publish`.

```elixir
Pixie.publish "/my/channel", %{message: "Pixie is awesome!"}
```

### Receiving messages from the server

You can subscribe to a channel and receive messages on that channel using
`Pixie.subscribe`.

```elixir
{:ok, pid} = Pixie.subscribe "/my/channel", fn (message, _pid)->
  IO.puts "Received message: #{inspect message}"
end
```

A separate worker process is created for each subscription, and it's pid is
both returned from the `subscribe` call, but also passed as the second argument
into the callback function, which means that you can do things like receive a
single message, then unsubscribe:

```elixir
Pixie.subscribe "/only_one_message", fn(message, pid)->
  IO.puts "Received message: #{inspect message}"
  Pixie.unsubscribe pid
end
```

Either way, you can use `Pixie.unsubscribe pid` to unsubscribe and terminate
the subscription process.

### Writing extensions

Pixie supports extensions which allow you to modify messages as they come into
the server.  You can write your own module and use the `Pixie.Extension`
behaviour.  Your extension needs only implement two functions:

  - `incoming %Pixie.Event{}` which returns a (possibly) modified event.
  - `outgoing %Pixie.Message.Publish{}` which returns a (possibly) modified
     message.

The `Pixie.Event` struct contains the following fields:

  - `client_id`: The ID of the Client.  You can use this to find `Pixie.Client`
                 and `Pixie.Transport` processes should you need to.
  - `message`:   The incoming message from the client. Messages are represented
                 as:
    - `%Pixie.Message.Handshake{}`:   A client handshake request.
    - `%Pixie.Message.Connect{}`:     A client connection request.
    - `%Pixie.Message.Subscribe{}`:   A subscription request.
    - `%Pixie.Message.Publish{}`:     A message to be published by the user.
    - `%Pixie.Message.Unsubscribe{}`: An unsubscription request.
    - `%Pixie.Message.Disconnect{}`:  A client disconnection request.
  - `response`:  The response to be sent back to the client.  You can use the
                 functions in `Pixie.Protocol.Error` (automatically imported
                 for you) or you can modify the response directly.

The details of all these structs should be available on
[hexdocs.pm](http://hexdocs.pm/pixie/overview.html).

You can configure Pixie to load your extensions at start-up (as per the
configuration section above) or you can add and remove them at runtime.

```elixir
Pixie.ExtensionRegistry.register MyExtension

# ... and ...

Pixie.ExtensionRegistry.unregister MyExtension
```

### Writing Monitors

Pixie provides monitoring functionality which allows you to subscribe to events
which are happennings in the system.

Provided events are:

  - Client created.
  - Client destroyed.
  - Channel created.
  - Channel destroyed.
  - Client subscribed to channel.
  - Client unsubscribed to channel.
  - Message received for publication.
  - Message delivered to receiving client.

All events also receive a [Timex](https://hex.pm/packages/timex) timestamp
recording the time at which they were generated - as there are potentially
a lot of them and they may sit in a process mailbox for some time.

You can use the `Pixie.Monitor` behaviour to define your event handler:

```elixir
defmodule MyMonitor do
  use Pixie.Monitor

  def created_channel channel_name, at do
    Logger.info "Channel \#\{channel_name} created at \#\{format at}")}"
  end

  def destroyed_channel channel_name, at do
    Logger.info "Channel \#\{channel_name} destroyed at \#\{format at}")}"
  end

  defp format timestamp do
    timestamp
      |> Date.from(:timestamp)
      |> DateFormat.format!("{UNIX}")
  end
end
```

Or you can use your own `GenEvent` handler, if the monitor API doesn't work
for you.

You can find more information in the [documentation](http://hexdocs.pm/pixie/overview.html).

## Running the tests

Run `mix espec`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
