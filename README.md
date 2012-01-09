# Leadlight [![Build Status](https://secure.travis-ci.org/avdi/leadlight.png)](http://travis-ci.org/avdi/leadlight)

Rose colored stained glass windows for HTTP.


## Goals

### Progressive enhancement for HTTP APIs

Don't cover up the web; just fill in the gaps here and there. Make it easy to
add links and other affordances API publishers might have forgotten.

### Model RESTful APIs as a web of links

Don't try to make the web look like a database.

### Representations over resources

Resources are the server's job to worry about. The things we get back from a
server are representations. Take representations at face value and interpret
them sensibly, rather than trying to fit them into a client-side model of an
imaginary server-side object graph.

### Support current and emerging standards

Such as the [Link header][], [URI templates][], [PATCH][], [ETags][], and
[JSON-schema][].

### Sensible defaults

Always try to convert representations returned by the server into a form that is
useful to the programmer--whether that is a Hash parsed from JSON data, a
Nokogiri document, or a text string.

### Backend agnostic

Using the power of [Faraday][].

### Exception-free

Only raise exceptions in API calls which explicitly request them. Provide ample
information to explain the cause of a failure.

### Async-ready

Architected from the ground up with asynchrony in mind. It's easier to build a
synchronous API on top of an async one than vice-versa.

### Controlled abstraction leakage

All abstractions are leaky. Provide ample and convenient access points into the
guts of the request lifecycle for situations when the defaults are not
sufficient.


[link header]:   http://tools.ietf.org/html/draft-nottingham-http-link-header
[uri templates]: http://tools.ietf.org/html/draft-gregorio-uritemplate
[patch]:         http://tools.ietf.org/html/rfc5789
[etags]:         http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.19
[json-schema]:   http://tools.ietf.org/html/draft-zyp-json-schema
[faraday]:       https://github.com/technoweenie/faraday


## Installation

```ruby
gem 'leadlight'
```

## Usage

_See
[leadlight_spec.rb](https://github.com/avdi/leadlight/blob/master/spec/leadlight_spec.rb)
for now._
