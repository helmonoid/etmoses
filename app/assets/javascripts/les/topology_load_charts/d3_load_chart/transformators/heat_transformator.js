var HeatTransformator = (function () {
    'use strict';

    function fetchChart(data, totals) {
        var chart,
            subChart,
            totals = (totals || []);

        for (chart in data) {
            if (data.hasOwnProperty(chart)) {
                subChart = data[chart];

                if (subChart.length && subChart.length > 0) {
                    totals.push({
                        type: chart,
                        name: I18n.t("charts." + chart),
                        area: true,
                        values: { total: LoadSlicer.slice(subChart, 0) }
                    });
                } else {
                    fetchChart(subChart, totals);
                }
            }
        };

        return totals;
    }

    return {
        transform: function (data, week) {
            return fetchChart(data);
        }
    }
}());
