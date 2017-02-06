class JobsTestCase extends ClassyTestCase
  @testName: 'jobs'

  testServertPlaintextActivityEmail: ->
    emailId = Random.id()

    class LocalActivity extends Activity
      @Meta
        name: 'LocalActivity'
        collection: null

    LocalActivity.documents.insert
      timestamp: new Date 'Mon Feb 06 2017 00:30:15 GMT-0800 (PST)'
      connection: null
      byUser:
        _id: 'H9TBeRafiSbNLEWQP'
        username: 'UserName'
        avatars: 'avatar/H9TBeRafiSbNLEWQP-i.svg?91ebc92a04473ded'
      forUsers: []
      type: 'discussionCreated'
      level: Activity.LEVEL.GENERAL
      data:
        discussion:
          _id: 'Y42FmLkdvkdwmS7FM'
          title: 'A discussion with a very very very long title which should wrap multiple lines, but we have to make sure this really happens'
    LocalActivity.documents.insert
      timestamp: new Date 'Mon Feb 06 2017 00:38:45 GMT-0800 (PST)'
      connection: null
      byUser:
        _id: 'H9TBeRafiSbNLEWQP'
        username: 'UserName'
        avatars: 'avatar/H9TBeRafiSbNLEWQP-i.svg?91ebc92a04473ded'
      forUsers: []
      type: 'commentCreated'
      level: Activity.LEVEL.GENERAL
      data:
        discussion:
          _id: 'Z8eaovjaFpR3pxtQc'
          title: 'TestDiscussionWithoutAnySpaceSoThatItCannotBeWrappedButItIsTooLongForALine'
        comment:
          _id: 'uhzmWNXuhzux2EaHK'

    userActivities = LocalActivity.documents.find().fetch()

    ActivityEmailsComponent = UIComponent.getComponent 'ActivityEmailsComponent'

    urlRoot = Meteor.absoluteUrl()

    @assertEqual new ActivityEmailsComponent(userActivities, emailId).renderComponentToPlainText(), """
      Recent notifications

      UserName started a discussion A discussion with a very very very
      long title which should wrap multiple lines, but we have to make
      sure this really happens.
      Mon, Feb 6, 2017 12:30 AM
      #{urlRoot}discussion/Y42FmLkdvkdwmS7FM

      UserName commented on
      TestDiscussionWithoutAnySpaceSoThatItCannotBeWrappedButItIsTooLongForALine.
      Mon, Feb 6, 2017 12:38 AM
      #{urlRoot}discussion/Z8eaovjaFpR3pxtQc


      Notification preferences
      #{urlRoot}account/settings

    """

ClassyTestCase.addTest new JobsTestCase()
