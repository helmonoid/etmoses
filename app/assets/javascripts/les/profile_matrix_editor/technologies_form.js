/*global AddedTechnologiesValidator,AddTechnology,ETHelper,TemplateUpdater,
Technology,TechnologyTemplateFinalizer*/

var TechnologiesForm = (function () {
    'use strict';

    function updateTemplate(e) {
        var template = $(".technology_template .technology");

        this.currentSelectBox = $(e.target);

        new TemplateUpdater(template, this.currentSelectBox).update();
    }

    function addListeners() {
        $(".add-technology select")
            .off('change')
            .on("change", updateTemplate.bind(this));

        $(".add-technology button")
            .off('click')
            .on("click", AddTechnology.add);
    }

    TechnologiesForm.prototype = {
        currentSelectBox: undefined,
        append: function () {
            $(".technologies .technology:not(.hidden)")
                .each(TechnologyTemplateFinalizer.update);

            this.setProfiles();
            addListeners.call(this);

            this.parseHarmonicaToJSON();

            AddedTechnologiesValidator.validate();
        },

        /*
         * Loops over all the technology <div> tags in the html and extract all the data
         * attributes.
         * It than writes the data several hidden <div> tags
         */
        parseHarmonicaToJSON: function () {
            var tableProfile = $(".technologies .technology:not(.hidden)")
                .toArray()
                .map(function (target) {
                    return $(target).underscorizedData();
                }),
                groupedByNode = ETHelper.groupBy(tableProfile, 'node');

            $("#technology_distribution").text(JSON.stringify(tableProfile));
            $("#testing_ground_technology_profile").text(JSON.stringify(groupedByNode));
        },

        updateCounter: function (add) {
            var addition = (!!add),
                amount   = (addition ? 1 : -1),
                countDom = $(this).parents(".endpoint").find("h4 .count"),
                count    = parseInt(countDom.text().replace(/[\(\)]/g, ''), 10);

            countDom.text("(" + (count += amount) + ")");
        },

        markAsEditing: function () {
            $("form.edit_testing_ground").addClass("editing");
            $("ul.nav.nav-tabs li a[href=#technologies]").addClass("editing");
        },

        setProfiles: function () {
            $(".technologies .technology:visible").each(function () {
                var profileSelect = $(this).find(".profile select"),
                    profileId = $(this).data('profile');

                profileSelect.val(profileId);
            });
        }
    };

    function TechnologiesForm() {
        return;
    }

    return TechnologiesForm;
}());

$(document).on("page:change", function () {
    'use strict';

    if ($("#profiles-table").length > 0) {
        window.currentTechnologiesForm = new TechnologiesForm();
        window.currentTechnologiesForm.append();
    }
});
