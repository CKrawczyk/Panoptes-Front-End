React = require 'react'
talkClient = require '../../api/talk'
Loading = require '../../components/loading-indicator'
Comment = require '../../talk/search-result'

module?.exports = React.createClass
  displayName: 'CommentNotification'

  propTypes:
    project: React.PropTypes.object
    user: React.PropTypes.object.isRequired
    notification: React.PropTypes.object.isRequired

  getInitialState: ->
    comment: null

  componentWillMount: ->
    talkClient.type('comments').get(@props.notification.source_id).then (comment) =>
      @setState {comment}

  render: ->
    if @state.comment
     <Comment
       data={@state.comment}
       user={@props.user}
       project={@props.project} />
    else
      <div className="talk-module">
        <Loading />
      </div>
