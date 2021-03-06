React = require 'react'
{Link} = require '@edpaget/react-router'
{Markdown} = require 'markdownz'
moment = require 'moment'
talkClient = require '../../api/talk'
apiClient = require '../../api/client'
Loading = require '../../components/loading-indicator'
Avatar = require '../../partials/avatar'

module?.exports = React.createClass
  displayName: 'ModerationNotification'

  propTypes:
    project: React.PropTypes.object
    user: React.PropTypes.object.isRequired
    notification: React.PropTypes.object.isRequired

  getInitialState: ->
    moderation: null
    comment: null
    commentUser: null
    reports: []

  componentWillMount: ->
    talkClient.type('moderations').get(@props.notification.source_id).then (moderation) =>
      comment = moderation.target or moderation.destroyed_target
      @setState {moderation, comment}

      promises = []
      for report in moderation.reports then do (report) =>
        promises.push apiClient.type('users').get(report.user_id.toString(), { }).then (user) =>
          report.user = user
          report

      apiClient.type('users').get(comment.user_id.toString()).then (commentUser) =>
        @setState {moderation, comment, commentUser}

      Promise.all(promises).then (reports) =>
        @setState {reports}

  render: ->
    notification = @props.notification
    path = if notification.project_id then 'project-talk-moderations' else 'talk-moderations'
    [owner, name] = notification.project_slug.split('/') if notification.project_slug

    if @state.moderation
      <div className="moderation talk-module">
        <div className="title">
          <Link to={path} {...@props} params={{owner, name}}>{notification.message}</Link>
        </div>

        <Markdown>{@state.comment.body}</Markdown>

        <p>Reports:</p>
        <ul>
          {for report, i in @state.reports
            <div key={"#{ @state.moderation.id }-report-#{ i }"}>
              <li>
                <Link className="user-profile-link" to="user-profile" params={name: report.user.login}>
                  <Avatar user={report.user} />{' '}{report.user.display_name}
                </Link>
                {': '}
                {report.message}
              </li>
            </div>}
        </ul>

        <div className="bottom">
          {if @state.commentUser
            <Link className="user-profile-link" to="user-profile" params={name: @state.commentUser.login}>
              <Avatar user={@state.commentUser} />{' '}{@state.commentUser.display_name}
            </Link>}

          {' '}

          <Link to={path} {...@props} params={{owner, name}}>
            {notification.message}{' '}
            {moment(notification.created_at).fromNow()}
          </Link>
        </div>
      </div>
    else
      <div className="talk-module">
        <Loading />
      </div>
