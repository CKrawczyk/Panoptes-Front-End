React = require 'react'
d3 = require 'd3'
ReactFauxDOM = require 'react-faux-dom'
qs = require 'qs'
PromiseRenderer = require '../../components/promise-renderer'
config = require '../../api/config'
{Model, makeHTTPRequest} = require 'json-api-client'

GraphD3 = React.createClass
  getDefaultProp: ->
    by: 'hour'
    data: []

  formatLabel:
    hour: (date) -> moment(date).format 'hh:mm A'

  render: ->
    parseDate = d3.time.format.iso.parse
    data = []
    @props.data.forEach ({label, value}) =>
      data.push {label: parseDate(label), value: value}

    data = data[-24..]

    margin = {top: 20, right: 20, bottom: 100, left: 70}
    width = 1200 - margin.left - margin.right
    height = 500 - margin.top - margin.bottom

    x = d3.scale.ordinal().rangeRoundBands([0, width], .05)
    y = d3.scale.linear().range([height, 0])

    xAxis = d3.svg.axis().scale(x).orient('bottom').tickFormat(d3.time.format('%m/%d %I:%M %p'))
    yAxis = d3.svg.axis().scale(y).orient('left')

    node = ReactFauxDOM.createElement('svg')
    svg = d3.select(node)
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
      .append('g')
      .attr('transform', "translate(#{margin.left},#{margin.top})")

    x.domain(data.map (d) => d.label)
    y.domain([0, d3.max(data, (d) => d.value)])

    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{height})")
      .call(xAxis)
      .selectAll('text')
      .style('text-anchor', 'end')
      .attr('dx', '-.8em')
      .attr('dy', '-.55em')
      .attr('transform', 'rotate(-45)')

    svg.append('g')
      .attr('class', 'y axis')
      .call(yAxis)

    svg.selectAll('bar')
      .data(data)
      .enter().append('rect')
      .style('fill', 'steelblue')
      .attr('x', (d) => x(d.label))
      .attr('width', x.rangeBand())
      .attr('y', (d) => y(d.value))
      .attr('height', (d) => height - y(d.value))

    <div style={background: 'white'}>
      {node.toReact()}
    </div>

ProjectStatsPage = React.createClass
  getDefaultProps: ->
    totalClassifications: 0
    requiredClassifications: 0
    totalVolunteers: 2
    currentVolunteers: 46
    classificationsBy: 'hour'
    volunteersBy: 'hour'

  classification_count: (period) ->
    stats_url = "#{config.statHost}/counts/classification/#{period}?project_id=#{@props.projectId}"
    # console.log stats_url
    makeHTTPRequest 'GET', stats_url
      .then (response) =>
        results = JSON.parse response.responseText
        bucket_data = results["events_over_time"]["buckets"]
        data = bucket_data.map (stat_object) =>
          label: stat_object.key_as_string
          value: stat_object.doc_count
        # console?.log data
      .catch (response) ->
        console?.error 'Failed to get the stats'

  volunteer_count: (period) ->
    []

  render: ->
    <div className="project-stats-page">
      <div className="project-stats-dashboard">
        <div className="major">
          {@props.totalClassifications}<br />
          Classifications
        </div>
        <div>
          {@props.totalVolunteers}<br />
          Volunteers
        </div>

        <div className="major">
          <meter value={@props.totalClassifications} max={@props.requiredClassifications} /><br />
          {Math.floor 100 * (@props.totalClassifications / @props.requiredClassifications)}% complete
        </div>
        <div>
          {@props.currentVolunteers}<br />
          Online now
        </div>
      </div>

      <div>
        Classifications per{' '}
        <select value={@props.classificationsBy} onChange={@handleGraphChange.bind this, 'classifications'}>
          <option value="hour">hour</option>
          <option value="day">day</option>
          <option value="week">week</option>
          <option value="month">month</option>
        </select><br />
        <PromiseRenderer promise={@classification_count(@props.classificationsBy)}>{(classificationData) =>
          <GraphD3 data={classificationData} by={@props.classificationsBy} />
        }</PromiseRenderer>
      </div>
    </div>

  handleGraphChange: (which, e) ->
    query = qs.parse location.search.slice 1
    query[which] = e.target.value
    location.search = qs.stringify query

ProjectStatsPageController = React.createClass
  render: ->
    # console.log @props
    queryProps =
      # classificationsBy: @props.query.classifications
      # volunteersBy: @props.query.volunteers
      projectId: @props.project.id
      totalClassifications: @props.project.classifications_count
      # there must be a better way to get this number
      requiredClassifications: @props.project.classifications_count / @props.project.completeness
      totalVolunteers: @props.project.classifiers_count
      currentVolunteers: @props.project.activity

    <ProjectStatsPage {...queryProps} />

module.exports = ProjectStatsPageController
