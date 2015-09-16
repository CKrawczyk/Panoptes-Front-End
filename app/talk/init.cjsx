React = require 'react'
BoardPreview = require './board-preview'
ActiveUsers = require './active-users'
talkClient = require '../api/talk'
HandlePropChanges = require '../lib/handle-prop-changes'
Moderation = require './lib/moderation'
ProjectLinker = require './lib/project-linker'
ROLES = require './lib/roles'
{Link} = require 'react-router'
CreateSubjectDefaultButton = require './lib/create-subject-default-button'
CreateBoardForm = require './lib/create-board-form'
Loading = require '../components/loading-indicator'
PopularTags = require './popular-tags'
require '../api/sugar'
ZooniverseTeam = require './lib/zoo-team.cjsx'
alert = require '../lib/alert'
AddZooTeamForm = require './add-zoo-team-form'
{Pager, PageNumberPager} = require('pagerz')

module?.exports = React.createClass
  displayName: 'TalkInit'
  mixins: [HandlePropChanges]

  propTypes:
    section: React.PropTypes.string # 'zooniverse' for main-talk, 'project_id' for projects

  propChangeHandlers:
    'section': 'setBoards'
    'user': 'setBoards'

  getInitialState: ->
    boards: []
    loading: true
    boardsMeta: {}

  componentWillMount: ->
    sugarClient.subscribeTo('zooniverse') if @props.section is 'zooniverse'

  componentWillUnmount: ->
    sugarClient.unsubscribeFrom('zooniverse') if @props.section is 'zooniverse'

  setBoards: (propValue, props = @props) ->
    talkClient.type('boards').get(section: props.section, page_size: 1)
      .then (boards) =>
        boardsMeta = boards[0]?.getMeta()
        @setState {boards, boardsMeta, loading: false}

  boardPreview: (data, i) ->
    <BoardPreview {...@props} key={i} data={data} />

  onPageChange: (page) ->
    talkClient.type('boards').get({
      section: @props.section,
      page_size: 1,
      page: page
    }).then (boards) =>
      boardsMeta = boards[0]?.getMeta()
      @setState {boards, boardsMeta}

  render: ->
    <div className="talk-home">
      {if @props.user?
        <Moderation section={@props.section} user={@props.user}>
          <div>
            <h2>Moderator Zone:</h2>

            {if @props.section isnt 'zooniverse'
              <CreateSubjectDefaultButton
                section={@props.section}
                onCreateBoard={=> @setBoards()} />
              }

            <ZooniverseTeam user={@props.user} section={@props.section}>
              <button className="link-style" type="button" onClick={=> alert (resolve) -> <AddZooTeamForm/>}>
                Invite someone to the Zooniverse team
              </button>
            </ZooniverseTeam>

            <Link
              to="#{if @props.section isnt 'zooniverse' then 'project-' else ''}talk-moderations"
              params={
                if (@props.params?.owner and @props.params?.name)
                  {owner: @props.params.owner, name: @props.params.name}
                else
                  {}
              }>
              View Reported Comments
            </Link>

            <CreateBoardForm section={@props.section} onSubmitBoard={=> @setBoards()}/>
          </div>
        </Moderation>}

      <div className="talk-list-content">
        <section>
          {if @state.loading
            <Loading />
           else if @state.boards?.length is 0
            <p>There are currently no boards.</p>}


          {if @state.boards.length > 0
            <Pager
              resourceProp={'data'}
              data={@state.boards}
              currentPage={@state.boardsMeta?.page}
              onPageChange={@onPageChange}
              pageCount={@state.boardsMeta?.page_count}
              nextPage={@state.boardsMeta?.next_page}
              previousPage={@state.boardsMeta?.previous_page}>
              <BoardPreview {...@props} />
            </Pager>
          }

        </section>

        <div className="talk-sidebar">
          <h2>Talk Sidebar</h2>

          <ProjectLinker user={@props.user} />

          <section>
            <PopularTags
              header={<h3>Popular Tags:</h3>}
              section={@props.section}
              params={@props.params} />
          </section>

          <section>
            <ActiveUsers section={@props.section} />
          </section>

          <section>
            <h3>
              {if @props.section is 'zooniverse'
                <Link className="sidebar-link" to="talk-recents" {...@props}>Recent Comments</Link>
              else
                <Link className="sidebar-link" to="project-talk-recents" {...@props}>Recent Comments</Link>
              }
            </h3>
          </section>
        </div>
      </div>
    </div>
