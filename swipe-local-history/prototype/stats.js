$(function () {
    $.get('/api/stats', function(stories) {
        setTimeout(function() {
            $('.loading').remove();
        }, 500);

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
                height: 150,
                width: 200,
                plotBackgroundColor: null,
                plotBorderWidth: 0,
                plotShadow: false
            },
            title: {
                text: '',
            },
            plotOptions: {
                pie: {
                    dataLabels: {
                        enabled: true,
                        distance: -10,
                        style: {
                            fontWeight: 'bold',
                            color: '#555',
                        }
                    },
                    startAngle: -90,
                    endAngle: 90,
                    size: '160%',
                    center: ['50%', '100%']
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
                type: 'pie',
                name: 'Favourites vs. Passes',
                innerSize: '70%',
                data: story.total_swipes !== 0 ? [
                    ['Favourites', story.favourites],
                    ['Passes', story.passes]
                ] : [],
            }],
            colors: ['#417505', '#a52105'],
        });
    }
});
