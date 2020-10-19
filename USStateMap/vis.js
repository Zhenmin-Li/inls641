// Start by loading the map data and the state statistics.  When those are done, call the "ready" function.
Promise.all([
    //d3.json("https://ils.unc.edu/~gotz/courses/data/us-states.json"),
    //d3.csv("https://ils.unc.edu/~gotz/courses/data/states.csv")
    d3.json("us-states.json"),
    d3.csv("tweets.v1.3.csv")
])
.then(ready);

// The callback which renders the page after the data has been loaded.
function ready(data) {
    // Render the poverty rate map. val_range is the range of data.
    render(data, "#mapsvg", [-1,0,1], "polarity");

    // Now render the life expectancy map.
    //render(data, "#mapsvg_le", [82,78,74], "life_expectancy");
}

// Helper function which, given the entire stats data structure, extracts the requested rate for the requested state
function getrate(stats, state_name, rate_type) {
    for (var i=0; i<stats.length; i++) {
        if (stats[i].location === state_name) {
            return stats[i][rate_type];
        }
    }
}

function getText(stats, state_name){
    for (var i=0; i< stats.length; i++){
    if (stats[i].location === state_name) {
        return stats[i]['text']
    }
  }
}

// Renders a map within the DOM element specified by svg_id.
function render(data, svg_id, val_range, rate_type) {
    let us = data[0];
    let stats = data[1];

    let projection = d3.geoAlbersUsa()
        .translate([800 / 2, 600 / 2]) // translate to center of screen
        .scale([1000]); // scale things down so see entire US

    // Define path generator
    let path = d3.geoPath().projection(projection);


    let svg = d3.select(svg_id);

    //svg.call(zoom);

    let colormap = d3.scaleLinear().domain(val_range).range(["#00293C", "#eeeeee", "#F62A00"]);

    svg.append("g")
        .attr("class", "states")
        .selectAll("path")
        .data(us.features)
        .enter().append("path")
        .attr("fill", function(d) { let rate=getrate(stats, d.properties.name, rate_type); return colormap(rate);})
        .attr("d", path)
        .on('mouseover', function(d){
            let detail_text ="<b>Raw Text:</b> "+ getText(stats, d.properties.name);
            let rate = getrate(stats, d.properties.name, rate_type);
            var decimal = d3.format(",.2f");
            document.getElementById('sentiment_text').innerHTML = 'The polarity of ' + d.properties.name + ' is '+ decimal(rate)+ '.';
            //document.getElementById('details').innerHTML = '\n' + detail_text;
        })
        .on("mouseout", function(d) { document.getElementById("sentiment_text").innerHTML = "&nbsp;"; })
        .call(d3.zoom()
            .scaleExtent([1, 2])
            .translateExtent([[-500,-300], [1500, 1000]])
            .on("zoom", function () {
            svg.attr("transform", d3.event.transform)
        }));

}
