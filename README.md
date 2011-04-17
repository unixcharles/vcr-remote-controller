VCR Remote Controller
=====================

VCR Remote Controller allow you to manage your VCR cassettes in development mode.
This Rack middleware let you select existing cassettes, create a new one, insert, eject
and see newly recorded request.

Based on the idea behind [Avdi Grimm](https://github.com/avdi) [screencast](http://avdi.org/devblog/2011/04/11/screencast-taping-api-interactions-with-vcr/) about VCR.

Usage
=====

    group :development do
      # ...
      gem 'vcr-remote-controller'
    end

    require 'vcr_remote_controller'
    use Rack::VcrRemoteController

And open your browser to /vcr-remote