# OpenCsp

OpenCsp is a Phoenix LiveView application that handles Content Security Policy (CSP) reports. It is designed to be a simple, self-hosted solution for teams who want to collect and analyze reports without spending a ton of money on a third-party service.

**This repo is brand new and still in the early stages of development.**

## Features

- [x] Receive and store CSP reports
- [x] View reports in a table
- [x] Stream CSP reports in real-time
- [x] Search / Filtering
- [x] Export
- [ ] Report grouping
- [ ] Notifications
- [ ] User management
- [ ] Policy builder

## Installation

### Docker Compose

To run locally, start up the server and a database with `docker compose up`.

To run migrations, use the following command:
```shell
docker compose exec web ./bin/open_csp eval "OpenCsp.Release.migrate"
```

### Local Development

This is a standard Phoenix application, so you can follow the standard Phoenix installation instructions. You will need to have Elixir and Erlang installed on your system. You can find instructions for installing Elixir [here](https://elixir-lang.org/install.html).

To start the server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000/violations`](http://localhost:4000/violations) from your browser.

## Using it in your application

Make sure to set the CSP report URL in your application to the `/report` path of your server. Note that some browsers may not support reports over http, so a tool like ngrok may be required for local development.
