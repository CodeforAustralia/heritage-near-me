$(function () {
    $('#story').change(function() {
        var storyIndex = $(this).val()
        if (storyIndex === null) {
            $('#chart').empty();
        } else {
            var story = $('#story').data('stories')[storyIndex];
            loadChart(story);
        }
    });

    $.get('/api/stats', function(stories) {
        $('#story').data('stories', stories);
        stories.forEach(function(story, index) {
            $('<option></option')
                .appendTo('#story')
                .val(index)
                .text(story.title);
        });
    });

    function loadChart(story) {
        console.log(story);
        $('#chart').highcharts({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: 0,
                plotShadow: false
            },
            title: {
                text: "'" + story.title + "'<br>Favourites",
                align: 'center',
                verticalAlign: 'middle',
                y: 40
            },
            plotOptions: {
                pie: {
                    dataLabels: {
                        enabled: true,
                        distance: -50,
                        style: {
                            fontWeight: 'bold',
                            color: 'white',
                            textShadow: '0px 1px 2px black'
                        }
                    },
                    startAngle: -90,
                    endAngle: 90,
                    center: ['50%', '75%']
                }
            },
            lang: {
                noData: "No one has interacted with this story yet",
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
            colors: ['#417505', '#754105'],
        });
    }
});
