# <img src="https://cdn.rawgit.com/peer/mind/master/packages/peermind/layout/logo.svg" width="24" height="24" /> PeerMind #

The goal of this application is to improve how we do group decision making in our communities.
Instead of just digitizing current voting practices and moving them online, without much added value,
this project aims to explore and improve technologies we use for decision making. Some current ideas:
* support for communities which meet offline, but want to use online tools to augment their decision making
* tools for better facilitation of discussions
* score voting for better multiple-choices decision making
* dynamic statistical quorum
* vote delegation
* visual feedback on decision making process and progress

The project is in early stages. Consider it a beta/prototype. Any feedback is welcome.

You can use it but keep in mind that it has not yet been security audited so you should
probably not use it for sensitive or critical decisions and where privacy of data and votes is
important.

## Development ##

The application uses [Meteor](https://www.meteor.com/) web framework. Install it:

```bash
curl https://install.meteor.com/ | sh
```

Clone the repository:

```bash
git clone --recursive https://github.com/peer/mind.git
```

Run it:

```bash
meteor
```

And open [http://localhost:3000/](http://localhost:3000/).

Currently you will have to manually create accounts using `meteor shell`:

```javascript
var userId = Package['accounts-base'].Accounts.createUser({username: 'admin', password: 'password'});
Package['alanning:roles'].Roles.addUsersToRoles(userId, ['admin', 'moderator', 'manager', 'member']);
```

Furthermore, currently the app has hard-coded four user roles with hard-coded permissions for them:
* `member`s can add discussion items, add comments to them, propose motions, upvote content, and vote on motions
* `moderator`s can make points, and edit content of others
* `manager`s can add discussion items, comment, and propose motions
* `admin`s can manage user accounts
* `guest`s can comment

After you have created an admin account, you can invite new users into the app. They will get an
e-mail with instructions how to setup their password. To invite a user, run the following function
in your browser's web console:

```javascript
Meteor.call('User.invite', 'email@example.com', 'name', console.log.bind(console));
```

Invited users initially do not belong to any role. Currently this means that effectively they cannot do anything
in the app without being added to at least one role. To add them to a role, you can use an admin interface at
[http://localhost:3000/admin/accounts](http://localhost:3000/admin/accounts).

### Used technologies ###

The application is built on top of many other technologies and Meteor packages:

* [Blaze](https://guide.meteor.com/blaze.html) for rendering HTML through [Blaze Components](http://components.meteorapp.com/) abstraction.
* [MongoDB](https://www.mongodb.com/) through [PeerDB](https://github.com/peerlibrary/meteor-peerdb) abstraction.
* [CoffeeScript](http://coffeescript.org/).
* [Material Design](https://material.google.com/) through [Materialize](http://materializecss.com/).
* [job-collection](https://github.com/vsivsi/meteor-job-collection/) for background tasks through [Classy Job](https://github.com/peerlibrary/meteor-classy-job) abstraction.

## Running ##

To run the application in production you can use [Docker](https://www.docker.com/).

The application is provided as [peermind/peermind](https://hub.docker.com/r/peermind/peermind/) Docker image.
It is based on [tozd/meteor](https://hub.docker.com/r/tozd/meteor/) image for Meteor applications.
[tozd/meteor-mongodb](https://hub.docker.com/r/tozd/meteor-mongodb/) image is recommended for MongoDB because
it creates necessary Meteor MongoDB database configuration automatically.

You can see [`run.sh`](https://github.com/peer/mind/blob/master/run.sh) file for an example how to run it.
**You have to adapt the script for your installation.** It contains hard-coded values for another installation.

## Related projects ##

* https://www.loomio.org/
* http://democracy.earth/
* https://airesis.eu/
* https://www.vilfredo.org/
