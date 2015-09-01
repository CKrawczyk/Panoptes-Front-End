React = require 'react'
talkClient = require '../api/talk'

module?.exports = React.createClass
  displayName: 'FollowDiscussion'

  propTypes:
    discussion: React.PropTypes.object.isRequired
    user: React.PropTypes.object.isRequired

  getInitialState: ->
    followed: null
    participating: false

  componentWillReceiveProps: (nextProps)->
    discussionId = nextProps.discussion?.id
    @getSubscriptionsFor(discussionId) if discussionId and discussionId isnt @props.discussion?.id

  toggleFollowed: (e) ->
    e.preventDefault()
    subscription = @state.subscriptions.followed_discussions
    if subscription
      @toggle subscription
    else
      @follow()

  toggleParticipating: (e) ->
    e.preventDefault()
    @toggle @state.subscriptions.participating_discussions

  toggle: (subscription) ->
    subscription.update(enabled: not subscription.enabled).save().then =>
      @getSubscriptionsFor @props.discussion.id

  follow: ->
    talkClient.type('subscriptions').create
      source_id: @props.discussion.id
      source_type: 'Discussion'
      category: 'followed_discussions'
    .save().then =>
      @getSubscriptionsFor @props.discussion.id

  buttonLabel: ->
    if @state.followed or @state.participating
      'Unsubscribe'
    else
      'Subscribe'

  followedText: ->
    if @state.followed
      "You're receiving notifications because you've subscribed to this discussion"
    else
      "Subscribe to receive notifications for updates to this discussion"

  getSubscriptionsFor: (id) ->
    talkClient.type('subscriptions').get
      source_id: id
      source_type: 'Discussion'
    .then (subscriptions) =>
      newState = subscriptions: { }, followed: null, participating: null, loaded: true

      for subscription in subscriptions
        newState.subscriptions[subscription.category] = subscription
        newState.followed = subscription.enabled if subscription.category is 'followed_discussions'
        newState.participating = subscription.enabled if subscription.category is 'participating_discussions'

      @setState newState

  render: ->
    <div className="talk-discussion-follow">
      {if @props.user and @state.loaded
        <div>
          {if @state.participating
            <div>
              <button onClick={@toggleParticipating}>{ @buttonLabel() }</button>
              <p className="description">You're receiving notifications from this discussion because you've joined it</p>
            </div>
          else
            <div>
              <button onClick={@toggleFollowed}>{@buttonLabel()}</button>
              <p className="description">{@followedText()}</p>
            </div>
          }
        </div>
      }
    </div>
