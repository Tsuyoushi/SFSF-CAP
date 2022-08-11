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

// Helper for employee create execution
async function executeCreateEmployee(req, userId) {
    const employee = await cds.tx(req).run(SELECT.one.from('Employee').columns(['userId']).where({ userId: { '=': userId } }));
    if (!employee) {
        const sfsfUser = await userService.tx(req).run(SELECT.one.from('User').columns(['userId', 'username', 'defaultFullName', 'email', 'division', 'department', 'title']).where({ userId: { '=': userId } }));
        if (sfsfUser) {
            await cds.tx(req).run(INSERT.into('Employee').entries(sfsfUser));
        }
    }
}

// Helper for employee update execution
async function executeUpdateEmployee(req, entity, entityID, userId) {
    // Need to check whether column has changed
    const column = 'member_userId';
    const query = SELECT.one.from(entity).columns([column]).where({ ID: { '=': entityID } });
    const item = await cds.tx(req).run(query);
    if (item && item[column] != userId) {
        // Member has changed, then:
        // Make sure there's an Employee entity for the new assignment
        await executeCreateEmployee(req, userId);

        // Create new assignment
        await createAssignment(req, entity, entityID, userId);
    }
    return req;
}

// Helper for assignment creation
async function createAssignment(req, entity, entityID, userId) {
    const columns =  m => { m.member_userId`as userId`, m.parent(p => { p.name`as name`, p.description`as description`, p.startDate`as startDate`, p.endDate`as endDate` }), m.role(r => { r.name`as role` }) };
    const item = await cds.tx(req).run(SELECT.one.from(entity).columns(columns).where({ ID: { '=': entityID } }));
    if (item) {
        const assignment = {
            userId: userId,
            project: item.parent.name,
            description: item.role.role + " of " + item.parent.description,
            startDate: item.parent.startDate,
            endDate: item.parent.endDate
        };
        console.log(assignment);
        const element = await assService.tx(req).run(INSERT.into('Background_SpecialAssign').entries(assignment));
        if (element) {
            await cds.tx(req).run(UPDATE.entity(entity).with({ hasAssignment: true }).where({ ID: entityID }));
        }
    }
    return req;
}

// Helper for cascade deletion
async function deepDelete(tx, ID, childEntity) {
    return await tx.run(DELETE.from(childEntity).where({ parent_ID: { '=': ID } }));
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

// Before create/update: member
async function createEmployee(req) {
    try {
        // Add SFSF User to Employees entity if it does not exist yet
        const item = req.data;
        const userId = (item.member_userId) ? item.member_userId : null;
        if (userId) {
            await executeCreateEmployee(req, userId);
        }
        return req;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

// After create: member
async function createItem(data, req) {
    try {
        // Create assignment in SFSF
        console.log('After create.');
        await createAssignment(req, req.entity, data.ID, data.member_userId);
        return data;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

// Before update: member
async function updateEmployee(req) {
    try {
        // Need to check if team member was updated
        if (req.data.member_userId) {
            const ID = (req.params[0]) ? ((req.params[0].ID) ? req.params[0].ID : req.params[0]) : req.data.ID;
            const userId = req.data.member_userId;
            await executeUpdateEmployee(req, req.entity, ID, userId);
        }
        return req;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

// Before delete: project or member
async function deleteChildren(req) {
    try {
        // Cascade deletion
        if (req.entity.indexOf('Project') > -1) {
            await deepDelete(cds.tx(req), req.data.ID, 'Activity');
            await deepDelete(cds.tx(req), req.data.ID, 'Member');
        } else {
            const item = await cds.tx(req).run(SELECT.one.from(req.entity).columns(['parent_ID']).where({ ID: { '=': req.data.ID } }));
            if (item) {
                await deepDelete(cds.tx(req), item.parent_ID, 'Activity');
            }
        }
        return req;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

// After delete/update: member
async function deleteUnassignedEmployees(data, req) {
    try {
        // Build clean-up filter
        const members = SELECT.distinct.from('Member').columns(['member_userId as userId']);
        const unassigned = SELECT.distinct.from('Employee').columns(['userId']).where({ userId: { 'NOT IN': members } });

        // Get the unassigned employees for deletion
        let deleted = await cds.tx(req).run(unassigned);

        // Make sure result is an array
        deleted = (deleted.length === undefined) ? [deleted] : deleted;

        // Clean-up Employees
        for (var i = 0; i < deleted.length; i++) {
            const clean_up = DELETE.from('Employee').where({ userId: { '=': deleted[i].userId } });
            await cds.tx(req).run(clean_up);
        }
        return data;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

// Before "save" project (exclusive for Fiori Draft support)
async function beforeSaveProject(req) {
    try {
        if (req.data.team) {
            // Capture IDs and users from saved members
            let users = []
            req.data.team.forEach(member => { users.push({ ID: member.ID, member_userId: member.member_userId }); });

            // Get current members
            let members = await cds.tx(req).run(SELECT.from('Member').columns(['ID', 'member_userId']).where({ parent_ID: { '=': req.data.ID } }));
            if (members) {
                // Make sure result is an array
                members = (members.length === undefined) ? [members] : members;

                // Process deleted members
                const deleted = [];
                members.forEach(member => {
                    const element = users.find(user => user.ID === member.ID);
                    if (!element) deleted.push(member);
                });
                for (var i = 0; i < deleted.length; i++) {
                    // Delete members' activities
                    await cds.tx(req).run(DELETE.from('Activity').where({ assignedTo_ID: { '=': deleted[i].ID } }));
                    if (req.data.activities) {
                        let idx = 0;
                        do {
                            idx = req.data.activities.findIndex(activity => activity.assignedTo_ID === deleted[i].ID);
                            if (idx > -1) {
                                req.data.activities.splice(idx, 1);
                            }
                        } while (idx > -1)
                    }
                }

                // Process added members
                const added = [];
                users.forEach(user => {
                    const element = members.find(member => user.ID === member.ID);
                    if (!element) added.push(user);
                });
                for (var i = 0; i < added.length; i++) {
                    await executeCreateEmployee(req, added[i].member_userId);
                }

                // Process updated members
                const updated = [];
                users.forEach(user => {
                    const element = members.find(member => user.ID === member.ID);
                    if (element) updated.push(user);
                });
                for (var i = 0; i < updated.length; i++) {
                    await executeUpdateEmployee(req, 'Member', updated[i].ID, updated[i].member_userId);
                }
            }
        }
        return req;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

// After "save" project (exclusive for Fiori Draft support)
async function afterSaveProject(data, req) {
    try {
        if (data.team) {
            // Look for members with unassigned elementId
            let unassigned = await cds.tx(req).run(SELECT.from('Member').columns(['ID', 'member_userId']).where({ parent_ID: { '=': data.ID }, and: { hasAssignment: { '=': false } } }));
            if (unassigned) {
                // Make sure result is an array
                unassigned = (unassigned.length === undefined) ? [unassigned] : unassigned;

                // Create SFSF assignment
                for (var i = 0; i < unassigned.length; i++) {
                    await createAssignment(req, 'Member', unassigned[i].ID, unassigned[i].member_userId);
                }
            }
        }
        await deleteUnassignedEmployees(data, req);

        return data;
    } catch (err) {
        req.error(err.code, err.message);
    }
}

module.exports = {
    readSFSF_User,
    createEmployee,
    createItem,
    updateEmployee,
    deleteChildren,
    deleteUnassignedEmployees,
    beforeSaveProject,
    afterSaveProject
}
