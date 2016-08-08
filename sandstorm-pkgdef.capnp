@0x9c4ab41b171187ca;

using Spk = import "/sandstorm/package.capnp";
# This imports:
#   $SANDSTORM_HOME/latest/usr/include/sandstorm/package.capnp
# Check out that file to see the full, documented package definition format.

const pkgdef :Spk.PackageDefinition = (
  # The package definition. Note that the spk tool looks specifically for the
  # "pkgdef" constant.

  id = "82wwsh623uvuu5htnjrry2ve668jdr13pep8751n4464t5hkjqch",
  # Your app ID is actually its public key. The private key was placed in
  # your keyring. All updates must be signed with the same key.

  manifest = (
    # This manifest is included in your app package to tell Sandstorm
    # about your app.

    appTitle = (defaultText = "PeerMind"),

    appVersion = 0,  # Increment this for every release.

    appMarketingVersion = (defaultText = "0.0.0"),
    # Human-readable representation of appVersion. Should match the way you
    # identify versions of your app in documentation and marketing.

    actions = [
      # Define your "new document" handlers here.
      ( nounPhrase = (defaultText = "community"),
        command = .myCommand
        # The command to run when starting for the first time. (".myCommand"
        # is just a constant defined at the bottom of the file.)
      )
    ],

    continueCommand = .myCommand,
    # This is the command called to start your app back up after it has been
    # shut down for inactivity. Here we're using the same command as for
    # starting a new instance, but you could use different commands for each
    # case.

    metadata = (
      # Data which is not needed specifically to execute the app, but is useful
      # for purposes like marketing and display.  These fields are documented at
      # https://docs.sandstorm.io/en/latest/developing/publishing-apps/#add-required-metadata
      # and (in deeper detail) in the sandstorm source code, in the Metadata section of
      # https://github.com/sandstorm-io/sandstorm/blob/master/src/sandstorm/package.capnp
      icons = (
        # Various icons to represent the app in various contexts.
        appGrid = (svg = embed ".sandstorm/appgrid.svg"),
        grain = (svg = embed ".sandstorm/grain.svg"),
        market = (svg = embed ".sandstorm/market.svg"),
      ),

      website = "http://peermind.org",
      # This should be the app's main website url.

      codeUrl = "https://github.com/peer/mind",
      # URL of the app's source code repository, e.g. a GitHub URL.
      # Required if you specify a license requiring redistributing code, but optional otherwise.

      license = (openSource = agpl3),
      # The license this package is distributed under.  See
      # https://docs.sandstorm.io/en/latest/developing/publishing-apps/#license

      categories = [communications, other],
      # A list of categories/genres to which this app belongs, sorted with best fit first.
      # See the list of categories at
      # https://docs.sandstorm.io/en/latest/developing/publishing-apps/#categories

      author = (
        # Fields relating to the author of this app.

        contactEmail = "mitar@tnode.com",
        # Email address to contact for any issues with this app. This includes end-user support
        # requests as well as app store administrator requests, so it is very important that this be a
        # valid address with someone paying attention to it.

        pgpSignature = embed ".sandstorm/pgp-signature",
        # PGP signature attesting responsibility for the app ID. This is a binary-format detached
        # signature of the following ASCII message (not including the quotes, no newlines, and
        # replacing <app-id> with the standard base-32 text format of the app's ID):
        #
        # "I am the author of the Sandstorm.io app with the following ID: <app-id>"
        #
        # You can create a signature file using `gpg` like so:
        #
        #     echo -n "I am the author of the Sandstorm.io app with the following ID: <app-id>" | gpg --sign > pgp-signature
        #
        # Further details including how to set up GPG and how to use keybase.io can be found
        # at https://docs.sandstorm.io/en/latest/developing/publishing-apps/#verify-your-identity

        #upstreamAuthor = "Example App Team",
        # Name of the original primary author of this app, if it is different from the person who
        # produced the Sandstorm package. Setting this implies that the author connected to the PGP
        # signature only "packaged" the app for Sandstorm, rather than developing the app.
        # Remove this line if you consider yourself as the author of the app.
      ),

      pgpKeyring = embed ".sandstorm/pgp-keyring",
      # A keyring in GPG keyring format containing all public keys needed to verify PGP signatures in
      # this manifest (as of this writing, there is only one: `author.pgpSignature`).
      #
      # To generate a keyring containing just your public key, do:
      #
      #     gpg --export <key-id> > keyring
      #
      # Where `<key-id>` is a PGP key ID or email address associated with the key.

      #description = (defaultText = embed "path/to/description.md"),
      # The app's description in Github-flavored Markdown format, to be displayed e.g.
      # in an app store. Note that the Markdown is not permitted to contain HTML nor image tags (but
      # you can include a list of screenshots separately).

      shortDescription = (defaultText = "Group decision making"),
      # A very short (one-to-three words) description of what the app does. For example,
      # "Document editor", or "Notetaking", or "Email client". This will be displayed under the app
      # title in the grid view in the app market.

      screenshots = [
        # Screenshots to use for marketing purposes.  Examples below.
        # Sizes are given in device-independent pixels, so if you took these
        # screenshots on a Retina-style high DPI screen, divide each dimension by two.

        #(width = 746, height = 795, jpeg = embed "path/to/screenshot-1.jpeg"),
        #(width = 640, height = 480, png = embed "path/to/screenshot-2.png"),
      ],
      #changeLog = (defaultText = embed "path/to/sandstorm-specific/changelog.md"),
      # Documents the history of changes in Github-flavored markdown format (with the same restrictions
      # as govern `description`). We recommend formatting this with an H1 heading for each version
      # followed by a bullet list of changes.
    ),
  ),

  sourceMap = (
    # The following directories will be copied into your package.
    searchPath = [
      ( sourcePath = ".meteor-spk/deps" ),
      ( sourcePath = ".meteor-spk/bundle" )
    ]
  ),

  alwaysInclude = [ "." ],
  # This says that we always want to include all files from the source map.
  # (An alternative is to automatically detect dependencies by watching what
  # the app opens while running in dev mode. To see what that looks like,
  # run `spk init` without the -A option.)

  bridgeConfig = (
    # Used for integrating permissions and roles into the Sandstorm shell
    # and for sandstorm-http-bridge to pass to your app.
    # Uncomment this block and adjust the permissions and roles to make
    # sense for your app.
    # For more information, see high-level documentation at
    # https://docs.sandstorm.io/en/latest/developing/auth/
    # and advanced details in the "BridgeConfig" section of
    # https://github.com/sandstorm-io/sandstorm/blob/master/src/sandstorm/package.capnp
    viewInfo = (
      # For details on the viewInfo field, consult "ViewInfo" in
      # https://github.com/sandstorm-io/sandstorm/blob/master/src/sandstorm/grain.capnp

      permissions = [
      # Permissions which a user may or may not possess.  A user's current
      # permissions are passed to the app as a comma-separated list of `name`
      # fields in the X-Sandstorm-Permissions header with each request.
      #
      # IMPORTANT: only ever append to this list!  Reordering or removing fields
      # will change behavior and permissions for existing grains!  To deprecate a
      # permission, or for more information, see "PermissionDef" in
      # https://github.com/sandstorm-io/sandstorm/blob/master/src/sandstorm/grain.capnp
        (
          name = "UPVOTE",
          # Name of the permission, used as an identifier for the permission in cases where string
          # names are preferred.  Used in sandstorm-http-bridge's X-Sandstorm-Permissions HTTP header.

          title = (defaultText = "upvote content"),
          # Display name of the permission, e.g. to display in a checklist of permissions
          # that may be assigned when sharing.

          description = (defaultText = "can upvote content"),
          # Prose describing what this role means, suitable for a tool tip or similar help text.
        ),
        (
          name = "COMMENT_NEW",
          title = (defaultText = "add comments"),
          description = (defaultText = "can add comments"),
        ),
        (
          name = "COMMENT_UPDATE",
          title = (defaultText = "edit comments"),
          description = (defaultText = "can edit comments"),
        ),
        (
          name = "COMMENT_UPDATE_OWN",
          title = (defaultText = "edit own comments"),
          description = (defaultText = "can edit own comments"),
        ),
        (
          name = "DISCUSSION_NEW",
          title = (defaultText = "add discussions"),
          description = (defaultText = "can add discussions"),
        ),
        (
          name = "DISCUSSION_UPDATE",
          title = (defaultText = "edit discussions"),
          description = (defaultText = "can edit discussions"),
        ),
        (
          name = "DISCUSSION_UPDATE_OWN",
          title = (defaultText = "edit own discussions"),
          description = (defaultText = "can edit own discussions"),
        ),
        (
          name = "MEETING_NEW",
          title = (defaultText = "add meetings"),
          description = (defaultText = "can add meetings"),
        ),
        (
          name = "MEETING_UPDATE",
          title = (defaultText = "edit meetings"),
          description = (defaultText = "can edit meetings"),
        ),
        (
          name = "MEETING_UPDATE_OWN",
          title = (defaultText = "edit own meetings"),
          description = (defaultText = "can edit own meetings"),
        ),
        (
          name = "MOTION_NEW",
          title = (defaultText = "add motions"),
          description = (defaultText = "can add motions"),
        ),
        (
          name = "MOTION_UPDATE",
          title = (defaultText = "edit motions"),
          description = (defaultText = "can edit motions"),
        ),
        (
          name = "MOTION_UPDATE_OWN",
          title = (defaultText = "edit own motions"),
          description = (defaultText = "can edit own motions"),
        ),
        (
          name = "MOTION_OPEN_VOTING",
          title = (defaultText = "open voting on motions"),
          description = (defaultText = "can open voting on motions"),
        ),
        (
          name = "MOTION_CLOSE_VOTING",
          title = (defaultText = "close voting on motions"),
          description = (defaultText = "can close voting on motions"),
        ),
        (
          name = "MOTION_WITHDRAW",
          title = (defaultText = "withdraw motions"),
          description = (defaultText = "can withdraw motions"),
        ),
        (
          name = "MOTION_WITHDRAW_OWN",
          title = (defaultText = "withdraw own motions"),
          description = (defaultText = "can withdraw own motions"),
        ),
        (
          name = "MOTION_VOTE",
          title = (defaultText = "vote on motions"),
          description = (defaultText = "can vote on motions"),
        ),
        (
          name = "POINT_NEW",
          title = (defaultText = "add points"),
          description = (defaultText = "can add points"),
        ),
        (
          name = "POINT_UPDATE",
          title = (defaultText = "edit points"),
          description = (defaultText = "can edit points"),
        ),
        (
          name = "POINT_UPDATE_OWN",
          title = (defaultText = "edit own points"),
          description = (defaultText = "can edit own points"),
        ),
        (
          name = "ACCOUNTS_ADMIN",
          title = (defaultText = "administer accounts"),
          description = (defaultText = "can administer accounts"),
        )
      ],
      roles = [
        # Roles are logical collections of permissions.  For instance, your app may have
        # a "viewer" role and an "editor" role
        (
          title = (defaultText = "member"),
          # Name of the role.  Shown in the Sandstorm UI to indicate which users have which roles.

          permissions  = [true, true, false, true, true, false, true, false, false, false, true, false, true, false, false, false, true, true, false, false, false, false],
          # An array indicating which permissions this role carries.
          # It should be the same length as the permissions array in
          # viewInfo, and the order of the lists must match.

          verbPhrase = (defaultText = "can add discussion items, add comments to them, propose motions, upvote content, and vote on motions"),
          # Brief explanatory text to show in the sharing UI indicating
          # what a user assigned this role will be able to do with the grain.

          description = (defaultText = "members participate in decision making process"),
          # Prose describing what this role means, suitable for a tool tip or similar help text.
        ),
        (
          title = (defaultText = "manager"),
          permissions  = [false, true, false, true, true, false, true, false, false, false, true, false, true, false, false, false, true, false, false, false, false, false],
          verbPhrase = (defaultText = "can add discussion items, comment, and propose motions"),
          description = (defaultText = "managers propose content, but cannot vote"),
        ),
        (
          title = (defaultText = "moderator"),
          permissions  = [false, false, true, false, false, true, false, true, true, false, false, true, false, true, true, true, false, false, true, true, false, false],
          verbPhrase = (defaultText = "can make points, and edit content of others"),
          description = (defaultText = "moderators make points and edit content"),
        ),
        (
          title = (defaultText = "admin"),
          permissions  = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true],
          verbPhrase = (defaultText = "can manage user accounts"),
          description = (defaultText = "admins manage the grain"),
        ),
      ],
    ),
  #  #apiPath = "/api",
  #  # Apps can export an API to the world.  The API is to be used primarily by Javascript
  #  # code and native apps, so it can't serve out regular HTML to browsers.  If a request
  #  # comes in to your app's API, sandstorm-http-bridge will prefix the request's path with
  #  # this string, if specified.
  ),
);

const myCommand :Spk.Manifest.Command = (
  # Here we define the command used to start up your server.
  argv = ["/sandstorm-http-bridge", "4000", "--", "node", "start.js"],
  environ = [
    # Note that this defines the *entire* environment seen by your app.
    (key = "PATH", value = "/usr/local/bin:/usr/bin:/bin"),
    (key = "SANDSTORM", value = "1"),
    # Export SANDSTORM=1 into the environment, so that apps running within Sandstorm
    # can detect if $SANDSTORM="1" at runtime, switching UI and/or backend to use
    # the app's Sandstorm-specific integration code.
    (key = "STORAGE_DIRECTORY", value = "/var/storage"),
    # Storage directory for content uploaded by users.
  ]
);
