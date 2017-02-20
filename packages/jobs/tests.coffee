class JobsTestCase extends ClassyTestCase
  @testName: 'jobs'

  testServertPlaintextActivityEmail: ->
    emailId = Random.id()

    class LocalActivity extends Activity
      @Meta
        name: 'LocalActivity'
        collection: null
        local: true

    timestamp1 = new Date 'Mon Feb 06 2017 00:30:15 GMT-0800 (PST)'
    timestamp2 = new Date 'Mon Feb 06 2017 00:38:45 GMT-0800 (PST)'
    timestamp3 = new Date 'Mon Feb 06 2017 00:44:11 GMT-0800 (PST)'

    LocalActivity.documents.insert
      timestamp: timestamp1
      connection: null
      byUser:
        _id: 'H9TBeRafiSbNLEWQP'
        username: 'UserName'
        avatar: 'avatar/H9TBeRafiSbNLEWQP-i.svg?91ebc92a04473ded'
      forUsers: []
      type: 'discussionCreated'
      level: Activity.LEVEL.GENERAL
      data:
        discussion:
          _id: 'Y42FmLkdvkdwmS7FM'
          title: 'A discussion with a very very very long title which should wrap multiple lines, but we have to make sure this really happens'
    LocalActivity.documents.insert
      timestamp: timestamp2
      connection: null
      byUser:
        _id: 'H9TBeRafiSbNLEWQP'
        username: 'UserName'
        avatar: 'avatar/H9TBeRafiSbNLEWQP-i.svg?91ebc92a04473ded'
      forUsers: []
      type: 'commentCreated'
      level: Activity.LEVEL.GENERAL
      data:
        discussion:
          _id: 'Z8eaovjaFpR3pxtQc'
          title: 'TestDiscussionWithoutAnySpaceSoThatItCannotBeWrappedButItIsTooLongForALine'
        comment:
          _id: 'uhzmWNXuhzux2EaHK'
    LocalActivity.documents.insert
      timestamp: timestamp3
      connection: null
      byUser:
        _id: 'kMJropJ93cJK6Pmos'
        username: 'UserName2'
        avatar: 'avatar/kMJropJ93cJK6Pmos-i.svg?75c16b5824cf06f0'
      forUsers: [
        _id: 'H9TBeRafiSbNLEWQP'
        username: 'UserName'
        avatar: 'avatar/H9TBeRafiSbNLEWQP-i.svg?91ebc92a04473ded'
      ]
      type: 'mention'
      level: Activity.LEVEL.USER
      data:
        discussion:
          _id: 'kMJropJ93cJK6Pmos'
          title: 'Let\'s build a submarine'
        comment:
          _id: 'YEetNMd2BP9iEZEfb'

    userActivities = LocalActivity.documents.find().fetch()

    ActivityEmailsComponent = UIComponent.getComponent 'ActivityEmailsComponent'
    component = new ActivityEmailsComponent "Recent notifications", userActivities, emailId

    urlRoot = Meteor.absoluteUrl()

    @assertEqual component.renderComponentToPlainText(), """
      Recent notifications

      UserName started a discussion A discussion with a very very very
      long title which should wrap multiple lines, but we have to make
      sure this really happens.
      #{component.formatDate timestamp1, component.DEFAULT_DATETIME_FORMAT}
      #{urlRoot}discussion/Y42FmLkdvkdwmS7FM

      UserName commented on
      TestDiscussionWithoutAnySpaceSoThatItCannotBeWrappedButItIsTooLongForALine.
      #{component.formatDate timestamp2, component.DEFAULT_DATETIME_FORMAT}
      #{urlRoot}discussion/Z8eaovjaFpR3pxtQc

      UserName2 mentioned you in a comment on Let's build a submarine.
      #{component.formatDate timestamp3, component.DEFAULT_DATETIME_FORMAT}
      #{urlRoot}discussion/kMJropJ93cJK6Pmos


      Notification preferences
      #{urlRoot}account/settings

    """

ClassyTestCase.addTest new JobsTestCase()
