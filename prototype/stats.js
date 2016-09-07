$(function () {
    $.get('/api/stats', function(stories) {
        setTimeout(function() {
            $('.loading').remove();
        }, 500);

        viewChart($('#views-chart'), stories);

        stories.forEach(function(story) {
            var element = $('<li></li>').appendTo('#favourites');
            var chart = $('<div></div>')
                .css('display', 'inline-block')
                .appendTo(element);
            var title = $('<h3></h3>')
                .text(story.title)
                .css('display', 'inline-block')
                .appendTo(element);

            setTimeout(function() {
                favouriteChart(chart, story);
            }, 600);
        });
    });

    function favouriteChart(element, story) {
        element.highcharts({
            chart: {
                type: 'bar',
                height: 150,
                width: 200,
                plotBackgroundColor: null,
                plotBorderWidth: 0,
                plotShadow: false
            },
            xAxis: {
                categories: ['Favourites', 'Passes'],
                title: {
                  text: null
                }
            },
            yAxis: {
                min: 0,
                title: {
                    text: 'Total',
                    align: 'high'
                },
                labels: {
                  overflow: 'justify'
                }
            },
            title: {
                text: '',
            },
            plotOptions: {
                bar: {
                    dataLabels: {
                        enabled: true,
                        distance: -10,
                        style: {
                            fontWeight: 'bold',
                            color: '#555',
                        }
                    },
                    size: '160%'
                    // center: ['50%', '100%']
                }
            },
            lang: {
                noData: "No one has interacted with this story yet",
            },
            noData: {
                useHTML: true,
                style: {
                    'width': '100%',
                    'white-space': 'nowrap',
                },
            },
            series: [{
                type: 'bar',
                name: 'Favourites vs. Passes',
                innerSize: '70%',
                data: story.total_swipes !== 0 ? [
                    ['Favourites', story.favourites],
                    ['Passes', story.passes]
                ] : [],
            }],
            // colors: ['#a52105', '#417505', '#a52105'],
        });
    }

    function viewChart(element, stories) {
        element.highcharts({
            chart: {
                height: 600,
                plotBackgroundColor: null,
                plotBorderWidth: 0,
                plotShadow: false
            },
            title: {
                text: 'Story views',
            },
            series: [{
                type: 'column',
                name: 'Story',
                data: stories.map(function(story) {
                    return [story.title, story.views];
                }),
            }],
            yAxis: {
                allowDecimals: false,
            }
        });
    }

});
