# Pixie

[ ![Codeship Status for messagerocket/pixie](https://codeship.com/projects/eb1dde70-2d10-0133-c122-16954c8f6a18/status?branch=master)](https://codeship.com/projects/98754)

*Pixie is a [Faye](http://faye.jcoglan.com) compatible Bayeux implementation*

*WARNING: Pixie is under heavy development.*

Pixie is inspired by Faye and was originally planned as a port, but has
diverged significantly as I've learned the Erlang way of modelling these
sorts of problems.

## Installation

Add `pixie` to your dependencies in the `mix.exs` file:

```elixir
def deps do
  # ...
  {:pixie, "~> 0.0.1"}
  # ...
end
```

Then use `mix deps.get` to download Pixie from [hex](https://hex.pm/).

## Supported messages

The server is under heavy development, at the moment it can handle the
following message types:

  - Handshake
  - Connect
  - Disconnect

over the following transports:

  - Long polling

## Usage

As the server doesn't really do anything at the moment in development I'm
running `mix pixie.server`, opening [localhost:4000](http://localhost:4000)
in my browser and manually starting a Faye client:


```javascript
client = new Faye.Client("http://localhost:4000/pixie");
client.connect();
```
