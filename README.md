# callfuture.me

Ever wanted to call yourself in the future? Now you can!

callfuture.me is a free service that allows you to leave a recording for
yourself which you will receive at a designated time in the future. You can use
it for anything -- maybe you want to remind yourself to take out the trash
tomorrow, or maybe you want to send a creepy message to yourself 5 years from
now.

This is the code that sits behind the callfuture.me web application.

## Technology

callfuture.me runs on a simple [Sinatra](http://sinatrarb.com) app hosted on
[Heroku](http://heroku.com). Telephony stuff is provided by
[Twilio](http://twilio.com) using the [unofficial twilio
gem](https://github.com/webficient/twilio). Messages are persisted to
[MongoDB](http://mongodb.org) (using
[MongoMapper](http://github.com/jnunemaker/mongomapper)) and scheduled using
[resque](http://github.com/defunkt/resque) and
[resque-scheduler](http://github.com/bvandenbos/resque-scheduler).

## Running the app locally

To run the app, you'll need to install Redis and MongoDB. On OS X this is as
simple as:

    brew install redis mongodb

Now install the gem dependencies:

    bundle install

Now ensure that Redis and MongoDB are running:

    bundle exec rake redis:start mongo:start

## Problems/Suggestions?

File an issue in [Issues](http://github.com/mcmire/callfuture.me/issues), and I
will take a look. If you're feeling particularly charitable, clone the repo,
make a branch, and send me a pull request.

## Author/License

(c) 2012 Elliot Winkler. Released under the Creative Commons BY-NC-SA license.
Please read <http://creativecommons.org/licenses/by-nc-sa/3.0/> for more
information.

## Contact

If you need help or have any questions, you can get in touch with me through
these channels:

* Twitter ([@mcmire](http://twitter.com/mcmire))
* Email (<elliot.winkler@gmail.com>)
