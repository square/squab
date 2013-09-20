# Squab Human Oriented Event Bus

## What is squab?

Squab is an event stream or event system for humans.  It's primary goal is to
track changes for an environment and present them as a continuous stream of
notable things for easy triage and tracking.  It utilizes user and source
information to make filtering the stream easier for the stream subscriber

It's basically a twitter account for your environment with easy write
capabilities for many external clients.  It gives your environment a voice
that's pieced together by many sources.  This tool is most useful when the
majority of the things that change an environment are notifying it of their
changes.

## What isn't squab?

Squab is not a reliable message bus.  It's not intended to shuttle your production data around or power your production infrastructure.  It's not optimized for performance or scalability, it's just intended to make it easy to write text blobs to a central source and read them back out again.  The API is designed to be easy to use, not necessarily to be highly flexible or configurable.

## Technologies used

Squab is built on top of [Sinatra](http://www.sinatrarb.com/) to provide the API and WebUI.  

The backend is handled by [Sequel](http://sequel.rubyforge.org/) and [SQLite](http://www.sqlite.org/).  

Other database backends are theoretically supported via Sequel and should be mostly drop-in replacements, but given the nature of the data, no investigation or testing has gone into that.

## Installation

### The Squab Server

```
gem install squab
/usr/bin/squab
```

You now have a squab instance running on [http://localhost:8082]().  You can modify the port, where the DB is stored, etc by taking defaults.yaml, modifying it, and placing it at /etc/squab.yaml.

### The Squab Client

```
gem install squab-client
/usr/bin/squawk -a http://localhost:8082 Test Message
```

The squab client comes with a CLI example of the client library usage for sending messages and can be used to send ad-hoc style messages before beginning some change on a server or the like.

### The Squab IRC Bot

```
gem install squab-bot
```

After installing the squab-bot gem, modify the squab-bot.yaml file with the IRC server, channels, bot nick, etc that you'd like to use.  Place this file at /etc/squab-bot.yaml

Now run:

```
/usr/bin/squab-bot
```

Your bot should join its home channel.  You can ask the bot for usage help by typing:

```
squab: help
```

In whatever channel you sent it to.  Naturally if you changed the bot's nick, you'll have to modify that command.


## Development

### Local Squab Server

Squab uses Bundler for local development.  After cloning this repository you can run:


```
cd squab
bundle install
bundle exec bin/squab
```

You can modify defaults.yaml and restart if you need a different port or database connect string or what have you

### Sending test messages

After you have a local version of the service running you can go to http://localhost:8082

You can post messages to this local squab using squawk:

```
cd squab-client
bundle install
bundle exec bin/squawk --api http://localhost:8082 A message to send
```

If you want to fake the user or source you can do:

```
bundle exec bin/squawk --api http://localhost:8082 -U username -S sourcename A message to send
```

If you want your message to link to a URL you can do:

```
bundle exec bin/squawk --api http://localhost:8081/api/v1/ --url http://example.com/cool A message that will link
```

### SquabClient

You can use the Ruby client for squab like so:

```
require 'squab-client'

sc = Squab::Client.new(
       api: "http://localhost:8081",
       source: "source",
       user: "username")

sc.send("Message", "http://url.to/somewhere")
```

All options to SquabClient.new are optional.

The API will default to http://squab/, so you might want to take a look at the api_url directive in squab.conf.example and add it to /etc/squab.conf.  This is the same config that the squab server uses, so don't just blow it away by copying the squab.yaml.example file into place.

The user defaults to the username of the person/thing running the script
The source defaults to the basename of the script

For send() the URL is optional as well.

### Squab IRC Bot

The Squab IRC Bot uses the [Isaac IRC framework](https://github.com/vangberg/isaac).  It generally just does responses to people talking to it.  It has a shortcut for posting messages.

Unfortunately the bot doesn't have a mocked IRC server or anything like that yet, so it's missing unit tests.  PRs welcome :)

### Gotchas

send() can fail and will raise a "SendEventFailed".  You should rescue that and move on if you don't care about your message hitting squab.

## Contributing

We'd love to have contributions.  This project is super useful to us, help us make it super useful to you and other people.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request 

# License
```
Copyright 2013 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
