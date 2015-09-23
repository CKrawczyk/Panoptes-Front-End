React = require 'react'
DrawingToolRoot = require './root'
DragHandle = require './drag-handle'
Draggable = require '../../lib/draggable'
DeleteButton = require './delete-button'

FINISHER_RADIUS = 8
GRAB_STROKE_WIDTH = 6
GUIDE_WIDTH = 1
GUIDE_DASH = [4, 4]

DELETE_BUTTON_WEIGHT = 3 # Weight of the second point.

module.exports = React.createClass
  displayName: 'CurveTool'

  statics:
    initCoords: null

    defaultValues: ({x, y}) ->
      points: []
      closed: false

    initStart: ({x, y}, mark) ->
      if mark.points.length > 0
        lastPoint = mark.points[mark.points.length - 1]
        cx = 0.5 * (x + lastPoint.x)
        cy = 0.5 * (y + lastPoint.y)
        mark.points.push {x: cx, y: cy}
      mark.points.push {x, y}
      points: mark.points

    initMove: ({x, y}, mark) ->
      mark.points[mark.points.length - 1] = {x, y}
      points: mark.points

    isComplete: (mark) ->
      mark.closed

    forceComplete: (mark) ->
      mark.closed = true
      mark.auto_closed = true

  componentWillMount: ->
    @setState
      mouseX: @props.mark.points[0].x
      mouseY: @props.mark.points[0].y
      mouseWithinViewer: true

  componentDidMount: ->
    document.addEventListener 'mousemove', @handleMouseMove

  componentWillUnmount: ->
    document.removeEventListener 'mousemove', @handleMouseMove

  render: ->
    {points} = @props.mark
    averageScale = (@props.scale.horizontal + @props.scale.vertical) / 2
    finisherRadius = FINISHER_RADIUS / averageScale
    guideWidth = GUIDE_WIDTH / averageScale

    firstPoint = points[0]
    secondPoint = points[1]
    secondPoint ?=
      x: firstPoint.x + (finisherRadius * 2)
      y: firstPoint.y - (finisherRadius * 2)
    lastPoint = points[points.length - 1]

    deleteButtonPosition =
      x: (firstPoint.x + ((DELETE_BUTTON_WEIGHT - 1) * secondPoint.x)) / DELETE_BUTTON_WEIGHT
      y: (firstPoint.y + ((DELETE_BUTTON_WEIGHT - 1) * secondPoint.y)) / DELETE_BUTTON_WEIGHT

    svgPath = "M#{firstPoint.x} #{firstPoint.y} "
    svgPathHelpers = "M#{firstPoint.x} #{firstPoint.y} "
    if points.length > 1
      for idx in [1..points.length-1] by 2
        if points[idx+1]?
          svgPath += "Q #{points[idx].x} #{points[idx].y} #{points[idx+1].x} #{points[idx+1].y} "
          svgPathHelpers += "L #{points[idx].x} #{points[idx].y} L #{points[idx+1].x} #{points[idx+1].y} "
        else
          svgPath += "Q #{lastPoint.x} #{lastPoint.y} #{firstPoint.x} #{firstPoint.y}"
          svgPathHelpers += "L #{lastPoint.x} #{lastPoint.y} L #{firstPoint.x} #{firstPoint.y}"

    <DrawingToolRoot tool={this}>
      <Draggable onDrag={@handleMainDrag} disabled={@props.disabled}>
        <path d={svgPath} fill={'none' unless @props.mark.closed} />
      </Draggable>

      {if @props.selected
        <g>
          <DeleteButton tool={this} x={deleteButtonPosition.x} y={deleteButtonPosition.y} />
          <path d={svgPathHelpers} strokeWidth={guideWidth} strokeDasharray={GUIDE_DASH} />

          {if not @props.mark.closed and @props.mark.points.length and @state.mouseWithinViewer
            <line className="guideline" x1={lastPoint.x} y1={lastPoint.y} x2={@state.mouseX} y2={@state.mouseY} />}

          {if not @props.mark.closed and @props.mark.points.length > 2
            <line className="guideline" x1={lastPoint.x} y1={lastPoint.y} x2={firstPoint.x} y2={firstPoint.y} />}

          {for point, i in points
            <DragHandle key={i} x={point.x} y={point.y} scale={@props.scale} onDrag={@handleHandleDrag.bind this, i} />}

          {unless @props.mark.closed
            <g>
              <circle className="clickable" r={finisherRadius} cx={firstPoint.x} cy={firstPoint.y} stroke="transparent" onClick={@handleFinishClick} />
              <circle className="clickable" r={finisherRadius} cx={lastPoint.x} cy={lastPoint.y} onClick={@handleFinishClick} />
            </g>}
        </g>}
    </DrawingToolRoot>

  handleMouseMove: (e) ->
    xPos = e.pageX
    yPos = e.pageY

    mouseWithinViewer = if xPos < @props.containerRect.left || xPos > @props.containerRect.right
      false
    else if yPos < @props.containerRect.top || yPos > @props.containerRect.bottom
      false
    else
      true

    @setState
      mouseX: (xPos - @props.containerRect.left) / @props.scale.horizontal
      mouseY: (yPos - @props.containerRect.top) / @props.scale.vertical
      mouseWithinViewer: mouseWithinViewer

  handleFinishClick: ->
    firstPoint = @props.mark.points[0]
    lastPoint = @props.mark.points[@props.mark.points.length - 1]
    cx = 0.5 * (firstPoint.x + lastPoint.x)
    cy = 0.5 * (firstPoint.y + lastPoint.y)
    @props.mark.points.push {x: cx, y: cy}
    document.removeEventListener 'mousemove', @handleMouseMove

    @props.mark.closed = true
    @props.onChange()

  handleMainDrag: (e, d) ->
    for point in @props.mark.points
      point.x += d.x / @props.scale.horizontal
      point.y += d.y / @props.scale.vertical
    @props.onChange e

  handleHandleDrag: (index, e, d) ->
    @props.mark.points[index].x += d.x / @props.scale.horizontal
    @props.mark.points[index].y += d.y / @props.scale.vertical
    @props.onChange e
