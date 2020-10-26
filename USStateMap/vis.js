// Start by loading the map data and the state statistics.  When those are done, call the "ready" function.
Promise.all([

    d3.json("us-states.json"),
    d3.csv("tweets.v1.4.csv")
])
.then(ready);


let colormap = d3.scaleLinear().domain([-1,0,1]).range(["#00293C", "#eeeeee", "#F62A00"]);

// The callback which renders the page after the data has been loaded.
function ready(data) {

    //update the map using time slider
    render(data, "#mapsvg", [-1,0,1], "polarity", '2020-02-01');
    d3.select("#timeslide").on("input", function() {
        update(data, +this.value);

    });
    // Render the poverty rate map. val_range is the range of data.


    // Now render the life expectancy map.
    //render(data, "#mapsvg_le", [82,78,74], "life_expectancy");
}

function update(stats, value) {
    let tweets = stats[1];
    let states = stats[0];
    var date = getDate(tweets)
    document.getElementById("range").innerHTML= date[value];
    let inputValue = date[value];
    console.log(inputValue)
    render(stats, "#mapsvg", [-1,0,1], "polarity", inputValue);

    //d3.selectAll("states").data(states.features)//.enter()
        //.attr("fill", function(d) { let rate=getrate(stats, d.properties.name, inputValue, 'polarity'); return colormap(rate);})
}

/*function dateMatch(stats, value) {
    let tweets = stats[1];

    for (var i=0; i<tweets.length; i++){

        if (tweets[i]['date'] == inputValue){
            //this.parentElement.appendChild(this);
            inputValue =

        }else{
            return "#999";
        }
    }
    for (var i = 0; i< date.length; i++){
        console.log(inputValue)
        console.log(date[i])
        if (inputValue == date[i]) {
            //this.parentElement.appendChild(this);
            console.log('if')
            return  colormap(getrate(tweets,us.features.properties.name,'polarity'));
        } else {
            console.log('else')
            return "#999";
        };

    }
}*/




// Helper function which, given the entire stats data structure, extracts the requested rate for the requested state
function getrate(stats, state_name, date, rate_type) {
    for (var i=0; i<stats.length; i++) {
        if (stats[i].location == state_name && stats[i].date == date){
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

function getDate(stats){
    var date = []
    for (var i=0; i< stats.length; i++){
        date.push(stats[i]['date'])
    }
    return date.sort().filter(function(el,i,a){return i==a.indexOf(el)});
}



// Renders a map within the DOM element specified by svg_id.
function render(data, svg_id, val_range, rate_type,date) {
    let us = data[0];
    let stats = data[1];

    let projection = d3.geoAlbersUsa()
        .translate([800 / 2, 600 / 2]) // translate to center of screen
        .scale([1000]); // scale things down so see entire US

    // Define path generator
    let path = d3.geoPath().projection(projection);


    let svg = d3.select(svg_id);

    //svg.call(zoom);

    //let colormap = d3.scaleLinear().domain(val_range).range(["#00293C", "#eeeeee", "#F62A00"]);

    svg.append("g")
        .attr("class", "states")
        .selectAll("path")
        .data(us.features)
        .enter().append("path")
        .attr("fill", function(d) { let rate=getrate(stats, d.properties.name,date, rate_type); return colormap(rate);})
        .attr("d", path)
        .on('mouseover', function(d){
            let detail_text ="<b>Raw Text:</b> "+ getText(stats, d.properties.name);
            let rate = getrate(stats, d.properties.name,date, rate_type);
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
