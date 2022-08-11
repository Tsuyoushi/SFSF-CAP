const cds = require('@sap/cds');

const {
    readSFSF_User
} = require('./lib/handlers');

module.exports = cds.service.impl(async function () {
    /*** SERVICE ENTITIES ***/
    const {
        Project,
        Member,
        SFSF_User,
    } = this.entities;

    /*** HANDLERS REGISTRATION ***/
    // ON events
    this.on('READ', SFSF_User, readSFSF_User);

    // BEFORE events

    // AFTER events
});