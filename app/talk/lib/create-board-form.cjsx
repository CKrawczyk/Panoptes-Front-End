React = require 'react'
ROLES = require './roles'
talkClient = require '../../api/talk'

module?.exports = React.createClass
  displayName: 'CreateBoardForm'

  propTypes:
    section: React.PropTypes.string
    onSubmitBoard: React.PropTypes.func

  getInitialState: ->
    error: ''

  onSubmitBoard: (e) ->
    e.preventDefault()
    titleInput = @getDOMNode().querySelector('form input')
    descriptionInput = @getDOMNode().querySelector('form textarea')

    # permissions
    read = @getDOMNode().querySelector(".roles-read input[name='role-read']:checked").value
    write = @getDOMNode().querySelector(".roles-write input[name='role-write']:checked").value
    permissions = {read, write}

    title = titleInput.value
    description = descriptionInput.value
    section = @props.section

    board = {title, description, section, permissions}

    return @setState({error: 'Boards must have a title and description'}) unless title and description

    talkClient.type('boards').create(board).save()
      .then (board) =>
        titleInput.value = ''
        descriptionInput.value = ''
        @setState({error: ''})
        @props.onSubmitBoard?(board)
      .catch (e) =>
        @setState {error: e.message}

  roleReadLabel: (roleName, i) ->
    <label key={i}><input type="radio" name="role-read" defaultChecked={i is ROLES.length-1} value={roleName}/>{roleName}</label>

  roleWriteLabel: (roleName, i) ->
    <label key={i}><input type="radio" name="role-write" defaultChecked={i is ROLES.length-1}value={roleName}/>{roleName}</label>

  render: ->
    <form onSubmit={@onSubmitBoard}>
      <h3>Add a board:</h3>
      <input type="text" ref="boardTitle" placeholder="Board Title"/>

      <textarea ref="boardDescription" placeholder="Board Description"></textarea><br />

      <h4>Can Read:</h4>
      <div className="roles-read">{ROLES.map(@roleReadLabel)}</div>

      <h4>Can Write:</h4>
      <div className="roles-write">{ROLES.map(@roleWriteLabel)}</div>

      <button type="submit"><i className="fa fa-plus-circle" /> Create Board</button>
      {if @state.error
        <p className="submit-error">{@state.error}</p>}
    </form>
