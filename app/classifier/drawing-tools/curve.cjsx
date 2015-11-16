React = require 'react'
DrawingToolRoot = require './root'
DragHandle = require './drag-handle'
Draggable = require '../../lib/draggable'
DeleteButton = require './delete-button'

FINISHER_RADIUS = 8
GRAB_STROKE_WIDTH = 6
GUIDE_WIDTH = 1
GUIDE_DASH = [4, 4]
# fraction of line lenght along (x) and perpendicular (y) to the line to place control point
DEFAULT_CURVE = {x: 0.5, y: 0}

DELETE_BUTTON_WEIGHT = 2 # Weight of the second point.

module.exports = React.createClass
  displayName: 'CurveTool'

  statics:
    initCoords: null

    defaultValues: ({x, y}) ->
      points: []
      closed: false

    initStart: (newPoint, mark) ->
      if mark.points.length > 0
        lastEnd = mark.points[-1..][0]
        cp = @toImageFrame(lastEnd, newPoint, DEFAULT_CURVE)
        mark.points.push cp
      ###
      else if mark.points.length > 0
        # make the new control point in the same relitive position as the previous one
        [lastStart, lastControl, lastEnd] = mark.points[-3..]
        cpPrime = @toLineFrame(lastStart, lastEnd, lastControl)
        cp = @toImageFrame(lastEnd, newPoint, cpPrime)
        mark.points.push cp
      ###
      mark.points.push newPoint
      points: mark.points

    initMove: ({x, y}, mark) ->
      mark.points[mark.points.length - 1] = {x, y}
      points: mark.points

    isComplete: (mark) ->
      mark.closed

    forceComplete: (mark) ->
      mark.closed = true
      mark.auto_closed = true

    toLineFrame: (start, end, control) ->
      # Move the contorl point to a local frame
      # where the line is on the x-axis and has length 1
      dx = end.x - start.x
      dy = end.y - start.y
      dcx = control.x - start.x
      dcy = control.y - start.y
      con = 1 / ((dx * dx) + (dy * dy))
      x: ((dx * dcx) + (dy * dcy)) * con
      y: (-(dy * dcx) + (dx * dcy)) * con

    toImageFrame: (start, end, control) ->
      # Take a control point in the line frame
      # and move it to the image frame
      dx = end.x - start.x
      dy = end.y - start.y
      x: (dx * control.x) - (dy * control.y) + start.x
      y: (dy * control.x) + (dx * control.y) + start.y

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
    if not @props.mark.closed and @state.mouseWithinViewer and points.length
      #if points.length == 1
      lastEnd = lastPoint
      cpPrime = DEFAULT_CURVE
      ###
      else
        [lastStart, lastControl, lastEnd] = points[-3..]
        cpPrime = @constructor.toLineFrame(lastStart, lastEnd, lastControl)
      ###
      newPoint ={x: @state.mouseX, y: @state.mouseY}
      cp = @constructor.toImageFrame(lastEnd, newPoint, cpPrime)
      svgPathGuide = "M#{lastEnd.x} #{lastEnd.y} Q #{cp.x} #{cp.y} #{newPoint.x} #{newPoint.y}"

    <DrawingToolRoot tool={this}>
      <Draggable onDrag={@handleMainDrag} disabled={@props.disabled}>
        <path d={svgPath} fill={'none' unless @props.mark.closed} />
      </Draggable>

      {if @props.selected
        <g>
          <DeleteButton tool={this} x={deleteButtonPosition.x} y={deleteButtonPosition.y} />
          <path d={svgPathHelpers} strokeWidth={guideWidth} strokeDasharray={GUIDE_DASH} fill={'none'} />

          {if not @props.mark.closed and points.length and @state.mouseWithinViewer
            <path className="guideline" d={svgPathGuide} fill={'none'} />}

          {if not @props.mark.closed and @props.mark.points.length > 2
            <line className="guideline" x1={lastPoint.x} y1={lastPoint.y} x2={firstPoint.x} y2={firstPoint.y} />}

          {for point, i in points
            if i%2 != 0
              className = "open-drag-handle"
            else
              className = undefined
            <DragHandle className={className} key={i} x={point.x} y={point.y} scale={@props.scale} onDrag={@handleHandleDrag.bind this, i} />}

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
    [lastStart, lastControl, lastEnd] = @props.mark.points[-3..]
    #cpPrime = @constructor.toLineFrame(lastStart, lastEnd, lastControl)
    cpPrime = DEFAULT_CURVE
    cp = @constructor.toImageFrame(lastEnd, firstPoint, cpPrime)
    @props.mark.points.push cp
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
