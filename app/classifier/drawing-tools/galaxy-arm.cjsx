React = require 'react'
DrawingToolRoot = require './root'
DragHandle = require './drag-handle'
Draggable = require '../../lib/draggable'
DeleteButton = require './delete-button'

MINIMUM_SIZE = 5
GUIDE_WIDTH = 1
GUIDE_DASH = [4, 4]

DELETE_BUTTON_WEIGHT = 2 # Weight of the second point.

module.exports = React.createClass
  displayName: 'GalaxyArmTool'

  statics:
    initCoords: null

    defaultValues: ({x, y}) ->
      points: []

    initStart: ({x, y}, mark) ->
      mark.points = [{x, y}, {x, y}, {x, y}, {x, y}, {x, y}]
      points: mark.points

    initMove: (cursor, mark) ->
      xp = false
      {x, y} = mark.points[0]
      # get the width and height of the bounding box
      if cursor.x > x
        width = cursor.x - x
        xp = true
      else
        width = x - cursor.x
      yp = false
      if cursor.y > y
        height = cursor.y - y
        yp = true
      else
        height = y - cursor.y

      # depending on the aspect ratio find the postion of other points
      # the galaxy tip is placed in the middle of the short side
      # curve control points are placed in the middle of the long side
      if width > height
        xl = x
        c1y = y
        if xp
          c1x = x + 0.5 * width
          tx = x + width
        else
          c1x = x - 0.5 * width
          tx = x - width
        c2x = c1x
        if yp
          c2y = y + height
          ty = y + 0.5 * height
        else
          c2y = y - height
          ty = y - 0.5 * height
        yl = c2y
      else
        yl = y
        c1x = x
        if xp
          c2x = x + width
          tx = x + 0.5  * width
        else
          c2x = x - width
          tx = x - 0.5 * width
        xl = c2x
        if yp
          c1y = y + 0.5 * height
          ty = y + height
        else
          c1y = y - 0.5 * height
          ty = y - height
        c2y = c1y

      # mark.points = [
      # {pos of first point},
      # {curve conrol point 1},
      # {pos of arm tip},
      # {curve control point 2},
      # {pos of last point}]
      mark.points = [{x, y}, {x:c1x, y:c1y}, {x:tx, y:ty}, {x:c2x, y:c2y}, {x:xl, y:yl}]
      points: mark.points

    initValid: (mark) ->
      Math.abs(mark.points[0].x - mark.points[2].x) > MINIMUM_SIZE and Math.abs(mark.points[0].y - mark.points[2].y)

  render: ->
    {points} = @props.mark
    guideWidth = GUIDE_WIDTH / ((@props.scale.horizontal + @props.scale.vertical) / 2)

    deleteButtonPosition =
      x: (points[0].x + ((DELETE_BUTTON_WEIGHT - 1) * points[4].x)) / DELETE_BUTTON_WEIGHT
      y: (points[0].y + ((DELETE_BUTTON_WEIGHT - 1) * points[4].y)) / DELETE_BUTTON_WEIGHT

    # start at inital point
    svgPath = "M#{points[0].x} #{points[0].y} "
    # draw a quadratic Bezier curve to the tip using control point 1
    svgPath += "Q #{points[1].x} #{points[1].y} #{points[2].x} #{points[2].y} "
    # draw a quadratic Bezier curve from the tip using control point 2
    svgPath += "Q #{points[3].x} #{points[3].y} #{points[4].x} #{points[4].y} "
    # close the curve
    svgPath += "L #{points[0].x} #{points[0].y}"

    <DrawingToolRoot tool={this}>
      <Draggable onDrag={@handleMainDrag} disabled={@props.disabled}>
        <path d={svgPath} />
      </Draggable>

      {if @props.selected
        <g>
          <DeleteButton tool={this} x={deleteButtonPosition.x} y={deleteButtonPosition.y} />
          <line x1={points[0].x} y1={points[0].y} x2={points[1].x} y2={points[1].y} strokeWidth={guideWidth} strokeDasharray={GUIDE_DASH} />
          <line x1={points[1].x} y1={points[1].y} x2={points[2].x} y2={points[2].y} strokeWidth={guideWidth} strokeDasharray={GUIDE_DASH} />
          <line x1={points[2].x} y1={points[2].y} x2={points[3].x} y2={points[3].y} strokeWidth={guideWidth} strokeDasharray={GUIDE_DASH} />
          <line x1={points[3].x} y1={points[3].y} x2={points[4].x} y2={points[4].y} strokeWidth={guideWidth} strokeDasharray={GUIDE_DASH} />

          {for point, i in @props.mark.points
            <DragHandle key={i} x={point.x} y={point.y} scale={@props.scale} onDrag={@handleHandleDrag.bind this, i} />}
        </g>}
    </DrawingToolRoot>

  handleMainDrag: (e, d) ->
    for point in @props.mark.points
      point.x += d.x / @props.scale.horizontal
      point.y += d.y / @props.scale.vertical
    @props.onChange e

  handleHandleDrag: (index, e, d) ->
    @props.mark.points[index].x += d.x / @props.scale.horizontal
    @props.mark.points[index].y += d.y / @props.scale.vertical
    @props.onChange e
