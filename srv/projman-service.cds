using sfsf.projman.model.db as model from '../db/projman-model';
using PLTUserManagement as UM_API from '../srv/external/PLTUserManagement.csn';

namespace sfsf.projman.service;

service ProjectManager @(path : '/projman', requires : 'authenticated-user') {
    @odata.draft.enabled
    entity Project as projection on model.Project;
    annotate Project with @(requires: 'Admin');

    entity Member as
        select from model.Member {
            * ,
            member.defaultFullName as member_name
        };
    annotate Member with @(requires: 'Admin');

    entity Activity as projection on model.Activity;
    annotate Activity with @(requires: 'Admin');

    @readonly
    entity SFSF_User       as
        select from UM_API.User {
            key userId,
                username,
                defaultFullName,
                email,
                division,
                department,
                title
        };

    annotate SFSF_User with @(requires: 'Admin');    
    annotate SFSF_User with @(cds.odata.valuelist);

    annotate model.Employee with @(requires: 'Admin');
    annotate model.Role with @(requires: 'Admin');
    annotate model.Status with @(requires: 'Admin');
    
}