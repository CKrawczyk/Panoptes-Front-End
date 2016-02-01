React = require 'react'
{History} = require 'react-router'
ReactFauxDOM = require 'react-faux-dom'
qs = require 'qs'
PromiseRenderer = require '../../components/promise-renderer'
config = require '../../api/config'
{Model, makeHTTPRequest} = require 'json-api-client'

GraphD3 = React.createClass
  getDefaultProp: ->
    by: 'hour'
    data: []

  render: ->
    formatLabel =
      hour: d3.time.format('%b-%d %I:%M %p')
      day: d3.time.format('%b-%d-%Y')
      week: d3.time.format('%b-%d-%Y')
      month: d3.time.format('%b-%d-%Y')
    parseDate = d3.time.format.iso.parse
    data = []
    @props.data.forEach ({label, value}) =>
      data.push {label: parseDate(label), value: value}

    data = data[(-1*@props.num)..]

    margin = {top: 20, right: 20, bottom: 120, left: 70}
    width = 1200 - margin.left - margin.right
    height = 500 - margin.top - margin.bottom

    x = d3.scale.ordinal().rangeRoundBands([0, width], .05)
    y = d3.scale.linear().range([height, 0])

    xAxis = d3.svg.axis().scale(x).orient('bottom').tickFormat(formatLabel[@props.by])
    yAxis = d3.svg.axis().scale(y).orient('left')

    node = ReactFauxDOM.createElement('svg')
    svg = d3.select(node)
      #.attr('width', width + margin.left + margin.right)
      #.attr('height', height + margin.top + margin.bottom)
      .attr("preserveAspectRatio", "xMinYMin meet")
      .attr("viewBox", "0 0 1200, 500")
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
      .attr('transform', 'rotate(-90)')

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

    <div className="svg-container">
      {node.toReact()}
    </div>

ProgressD3 = React.createClass
  getDefaultProps: ->
    progress: 0

  render: ->
    width = 500
    height = 500
    formatPercent = d3.format('.0%')

    arc = d3.svg.arc()
      .startAngle(0)
      .innerRadius(180)
      .outerRadius(240)

    node = ReactFauxDOM.createElement('svg')
    svg = d3.select(node)
      #.attr('width', width)
      #.attr('height', height)
      .attr("preserveAspectRatio", "xMinYMin meet")
      .attr("viewBox", "0 0 500, 500")
      .append('g')
      .attr('transform', "translate(#{width / 2},#{height / 2})")

    meter = svg.append('g')
      .attr('class', 'progress-meter')

    meter.append('path')
      .attr('class', 'background')
      .attr('d', arc.endAngle(2 * Math.PI))

    foreground = meter.append('path')
      .attr('class', 'foreground')
      .attr('d', arc.endAngle(2 * Math.PI * @props.progress))

    text = meter.append('text')
      .attr('text-anchor', 'middle')
      .attr('dy', '.35em')
      .text("#{formatPercent(@props.progress)} Complete")

    <div className="svg-container progress-container">
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
    makeHTTPRequest 'GET', stats_url
      .then (response) =>
        results = JSON.parse response.responseText
        bucket_data = results["events_over_time"]["buckets"]
        data = bucket_data.map (stat_object) =>
          label: stat_object.key_as_string
          value: stat_object.doc_count
      .catch (response) ->
        console?.error 'Failed to get the stats'

  volunteer_count: (period) ->
    []

  render: ->
    <div className="project-stats-page content-container">
      <div className="project-stats-dashboard">
        <div className="major">
          Classifications: {@props.totalClassifications.toLocaleString()}
        </div>
        <ProgressD3 progress={@props.totalClassifications / @props.requiredClassifications} />
        <div>
          Volunteers: {@props.totalVolunteers.toLocaleString()}
        </div>
        <div>
          Online now: {@props.currentVolunteers.toLocaleString()}
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
          <GraphD3 data={classificationData} by={@props.classificationsBy} num={24} />
        }</PromiseRenderer>
      </div>
    </div>

  handleGraphChange: (which, e) ->
    @props.handleGraphChange(which, e)

ProjectStatsPageController = React.createClass
  mixins: [History]

  handleGraphChange: (which, e) ->
    query = qs.parse location.search.slice 1
    query[which] = e.target.value
    {owner, name} = @props.params
    @history.pushState(null, "/projects/#{owner}/#{name}/stats/", query)

  getQuery: (which) ->
    qs.parse(location.search.slice(1))[which]

  render: ->
    queryProps =
      handleGraphChange: @handleGraphChange
      classificationsBy: @getQuery('classifications') ? 'hour'
      volunteersBy: @getQuery('valunteerss') ? 'hour'
      projectId: @props.project.id
      totalClassifications: @props.project.classifications_count
      # there must be a better way to get this number
      requiredClassifications: @props.project.classifications_count / @props.project.completeness
      totalVolunteers: @props.project.classifiers_count
      currentVolunteers: @props.project.activity

    <ProjectStatsPage {...queryProps} />

module.exports = ProjectStatsPageController
