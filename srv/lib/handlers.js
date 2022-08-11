const cds = require('@sap/cds');

let userService = null;
let assService = null;

(async function () {
    // Connect to external SFSF OData services
    userService = await cds.connect.to('PLTUserManagement');
    assService = await cds.connect.to('ECEmployeeProfile');
})();

/*** HELPERS ***/

// Remove the specified columns from the ORDER BY clause of a SELECT statement
function removeColumnsFromOrderBy(query, columnNames) {
    if (query.SELECT && query.SELECT.orderBy) {
        columnNames.forEach(columnName => {
            // Look for column in query and its respective index
            const element = query.SELECT.orderBy.find(column => column.ref[0] === columnName);
            const idx = query.SELECT.orderBy.indexOf(element);

            if (idx > -1) {
                // Remove column from oder by list
                query.SELECT.orderBy.splice(idx, 1);
                if (!query.SELECT.orderBy.length) {
                    // If list ends up empty, remove it from query
                    delete query.SELECT.orderBy;
                }
            }
        });
    }

    return query;
}

/*** HANDLERS ***/

// Read SFSF users
async function readSFSF_User(req) {
    try {
        // Columns that are not sortable must be removed from "order by"
        req.query = removeColumnsFromOrderBy(req.query, ['defaultFullName']);

        // Handover to the SF OData Service to fecth the requested data
        const tx = userService.tx(req);
        return await tx.run(req.query);
    } catch (err) {
        req.error(err.code, err.message);
    }
}

module.exports = {
    readSFSF_User
}