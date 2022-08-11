using sfsf.projman.service.ProjectManager as service from './projman-service';

namespace sfsf.projman.service.ui;

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the Project Root Entity
//
annotate service.Project with @(UI : {
    UpdateHidden        : false,
    DeleteHidden        : false,
    CreateHidden        : false,
    Identification      : [
        {Value : name}
    ],
    HeaderInfo          : {
        $Type          : 'UI.HeaderInfoType',
        TypeName       : 'Project',
        TypeNamePlural : 'Projects',
        Title          : {
            $Type : 'UI.DataField',
            Value : name
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : description
        }
    },
    SelectionFields     : [
        name,
        startDate,
        endDate,
        status_ID
    ],
    LineItem            : [
        {
            $Type : 'UI.DataField',
            Value : name
        },
        {
            $Type : 'UI.DataField',
            Value : description
        },
        {
            $Type : 'UI.DataField',
            Value : startDate
        },
        {
            $Type : 'UI.DataField',
            Value : endDate
        },
        {
            $Type             : 'UI.DataField',
            Value             : status.name,
            Criticality       : status.criticality,
            ![@UI.Importance] : #High
        }
    ],
    HeaderFacets        : [{
        $Type  : 'UI.ReferenceFacet',
        Target : '@UI.FieldGroup#Detail'
    }],
    Facets              : [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'ProjectsDetails',
            Target : '@UI.FieldGroup#Details',
            Label  : 'Details'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'ProjcetTeam',
            Target : 'team/@UI.LineItem',
            Label  : 'Team'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'ProjcetActivity',
            Target : 'activities/@UI.LineItem',
            Label  : 'Activities'
        }
    ],
    DataPoint #ProjName : {
        Value : name,
        Title : 'Project Title'
    },
    FieldGroup #Detail  : {Data : [{
        $Type       : 'UI.DataField',
        Value       : status_ID,
        Criticality : status.criticality
    }]},
    FieldGroup #Details : {
        $Type : 'UI.FieldGroupType',
        Data  : [
            {
                $Type : 'UI.DataField',
                Value : startDate,
                Label : 'Start'
            },
            {
                $Type : 'UI.DataField',
                Value : endDate,
                Label : 'End'
            }
        ]
    },
});

annotate service.Project with {
    ID          @(
        title     : 'Project ID',
        UI.Hidden : true
    )           @readonly;
    name        @(title : 'Project Title');
    description @(
        title : 'Description',
        UI.MultiLineText
    );
    startDate   @(title : 'Start');
    endDate     @(title : 'End');
    status      @(
        Common : {
            Text            : status.name,
            TextArrangement : #TextOnly,
            ValueListWithFixedValues,
            FieldControl    : #Mandatory
        },
        title  : 'Status'
    );
}

annotate service.Project @(Capabilities : {
    Insertable : true,
    Deletable  : true,
    Updatable  : true,
});

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the Member Child Entity
//
annotate service.Member with @(UI : {
    UpdateHidden        : false,
    DeleteHidden        : false,
    CreateHidden        : false,
    Identification      : [{Value : member_name}],
    HeaderInfo          : {
        $Type          : 'UI.HeaderInfoType',
        TypeName       : 'Member',
        TypeNamePlural : 'Members',
        Title          : {
            $Type : 'UI.DataField',
            Value : member_userId
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : member.title
        }
    },
    SelectionFields     : [
        member.division,
        member.department,
        member.email,
        role.name
    ],
    LineItem            : [
        {
            $Type : 'UI.DataField',
            Value : member_userId,
            Label : 'Name'
        },
        {
            $Type : 'UI.DataField',
            Value : member.title
        },
        {
            $Type : 'UI.DataField',
            Value : member.email
        },
        {
            $Type : 'UI.DataField',
            Value : member.division
        },
        {
            $Type : 'UI.DataField',
            Value : member.department
        },
        {
            $Type : 'UI.DataField',
            Value : role_ID,
            Label : 'Role'
        }
    ],
    HeaderFacets        : [{
        $Type  : 'UI.ReferenceFacet',
        Target : '@UI.FieldGroup#Detail'
    }],
    Facets              : [{
        $Type  : 'UI.ReferenceFacet',
        ID     : 'ProjectsDetails',
        Target : '@UI.FieldGroup#Details',
        Label  : 'Details'
    }],
    FieldGroup #Detail  : {Data : [{
        $Type : 'UI.DataField',
        Value : role_ID,
        Label : 'Role'
    }]},
    FieldGroup #Details : {
        $Type : 'UI.FieldGroupType',
        Data  : [
            {
                $Type : 'UI.DataField',
                Value : member.email,
                Label : 'e-Mail'
            },
            {
                $Type : 'UI.DataField',
                Value : member.division,
                Label : 'Division'
            },
            {
                $Type : 'UI.DataField',
                Value : member.department,
                Label : 'Department'
            }
        ]
    },
});

annotate service.Member with {
    ID          @(
        Common : {
            Text : member_name,
            TextArrangement : #TextOnly,
        },
        title     : 'Member ID'
    )           @readonly;
    parent      @(
        title     : 'Project ID',
        UI.Hidden : true
    );
    member      @(
        Common : {
            Text            : member.defaultFullName,
            TextArrangement : #TextOnly,
            FieldControl    : #Mandatory,
            ValueList       : {
                $Type          : 'Common.ValueListType',
                CollectionPath : 'SFSF_User',
                Parameters     : [
                    {
                        $Type             : 'Common.ValueListParameterInOut',
                        LocalDataProperty : 'member_userId',
                        ValueListProperty : 'userId'
                    },
                    {
                        $Type             : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty : 'defaultFullName'
                    }
                ],
                Label : 'Employees'
            }
        },
        title  : 'Name'
    );
    role        @(
        Common : {
            Text            : role.name,
            TextArrangement : #TextOnly,
            ValueListWithFixedValues,
            FieldControl    : #Mandatory
        },
        title  : 'Role'
    );
    member_name @(title : 'Name', UI.Hidden: true);
    hasAssignment @(UI.Hidden: true);
}

annotate service.Member @(Capabilities : {
    SearchRestrictions : {
        $Type      : 'Capabilities.SearchRestrictionsType',
        Searchable : true
    },
    Insertable         : true,
    Deletable          : true,
    Updatable          : true
});

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the Activity Child Entity
//
annotate service.Activity with @(UI : {
    UpdateHidden        : false,
    DeleteHidden        : false,
    CreateHidden        : false,
    Identification      : [{Value : name}],
    HeaderInfo          : {
        $Type          : 'UI.HeaderInfoType',
        TypeName       : 'Activity',
        TypeNamePlural : 'Activities',
        Title          : {
            $Type : 'UI.DataField',
            Value : name
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : description
        }
    },
    SelectionFields     : [
        name,
        assignedTo_ID,
        dueDate,
        status_ID
    ],
    LineItem            : [
        {
            $Type : 'UI.DataField',
            Value : name
        },
        {
            $Type : 'UI.DataField',
            Value : description
        },
        {
            $Type : 'UI.DataField',
            Value : assignedTo_ID,
            Label : 'Assigned To'
        },
        {
            $Type : 'UI.DataField',
            Value : assignedTo.role.name
        },
        {
            $Type : 'UI.DataField',
            Value : dueDate
        },
        {
            $Type       : 'UI.DataField',
            Value       : status_ID,
            Label       : 'Status',
            Criticality : status.criticality
        }
    ],
    HeaderFacets        : [{
        $Type  : 'UI.ReferenceFacet',
        Target : '@UI.FieldGroup#Detail'
    }],
    Facets              : [{
        $Type  : 'UI.ReferenceFacet',
        ID     : 'ActivityDetails',
        Target : '@UI.FieldGroup#Details',
        Label  : 'Details'
    }],
    FieldGroup #Detail  : {Data : [{
        $Type       : 'UI.DataField',
        Value       : status_ID,
        Criticality : status.criticality
    }]},
    FieldGroup #Details : {
        $Type : 'UI.FieldGroupType',
        Data  : [
            {
                $Type : 'UI.DataField',
                Value : assignedTo_ID,
                Label : 'Assigned To'
            },
            {
                $Type : 'UI.DataField',
                Value : assignedTo.role.name,
                Label : 'Role'
            },
            {
                $Type : 'UI.DataField',
                Value : dueDate,
                Label : 'Due Date'
            }
        ]
    },
});

annotate service.Activity with {
    ID               @(
        title     : 'Activity ID',
        UI.Hidden : true
    )                @readonly;
    parent           @(
        title     : 'Project ID',
        UI.Hidden : true
    );
    name             @(title : 'Activity');
    description      @(
        title : 'Description',
        UI.MultiLineText
    );
    assignedTo       @(
        Common : {
            Text            : assignedTo.member_name,
            TextArrangement : #TextOnly,
            ValueListWithFixedValues,
            FieldControl    : #Mandatory,
            ValueList       : {
                $Type          : 'Common.ValueListType',
                CollectionPath : 'Member',
                Parameters     : [
                    {
                        $Type             : 'Common.ValueListParameterOut',
                        LocalDataProperty : 'assignedTo_ID',
                        ValueListProperty : 'ID'
                    },
                    {
                        $Type             : 'Common.ValueListParameterIn',
                        LocalDataProperty : 'parent_ID',
                        ValueListProperty : 'parent_ID'
                    },
                    {
                        $Type             : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty : 'member_name'
                    }
                ]
            }
        },
        title  : 'Assigned To'
    );
    dueDate @(title : 'Due Date');
    status           @(
        Common : {
            Text            : status.name,
            TextArrangement : #TextOnly,
            ValueListWithFixedValues,
            FieldControl    : #Mandatory
        },
        title  : 'Status'
    );
}

annotate service.Activity @(Capabilities : {
    SearchRestrictions : {
        $Type      : 'Capabilities.SearchRestrictionsType',
        Searchable : true
    },
    Insertable         : true,
    Deletable          : true,
    Updatable          : true
});

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the Employee Child Entity
//
annotate service.Employee with {
    userId          @(title : 'User ID')  @readonly;
    username        @(title : 'User Name')  @readonly;
    defaultFullName @(title : 'Name');
    email           @(title : 'e-Mail');
    division        @(title : 'Division');
    department      @(title : 'Department');
    title           @(title : 'Title');
}

annotate service.Employee @(Capabilities : {
    Insertable : false,
    Deletable  : false,
    Updatable  : false
});

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the SFSF_User Entity
//
annotate service.SFSF_User with @(UI : {
    CreateHidden    : true,
    UpdateHidden    : true,
    DeleteHidden    : true,
    Identification  : [{
        $Type : 'UI.DataField',
        Value : defaultFullName
    }],
    HeaderInfo      : {
        $Type          : 'UI.HeaderInfoType',
        TypeName       : 'User',
        TypeNamePlural : 'Users',
        Title          : {
            $Type : 'UI.DataField',
            Value : defaultFullName
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : title
        }        
    },
    SelectionFields : [
        userId,
        username,
        division,
        department
    ],
    LineItem        : [
        {
            $Type : 'UI.DataField',
            Value : userId
        },
        {
            $Type : 'UI.DataField',
            Value : defaultFullName
        },
        {
            $Type : 'UI.DataField',
            Value : email
        },
        {
            $Type : 'UI.DataField',
            Value : title
        },
        {
            $Type : 'UI.DataField',
            Value : division
        },
        {
            $Type : 'UI.DataField',
            Value : department
        }
    ],
});

annotate service.SFSF_User with {
    userId          @(
        Common : {
            Text : defaultFullName,
            TextArrangement : #TextSeparate
        },
        title : 'User ID'
    )  @readonly;
    username        @(title : 'User Name')  @readonly;
    defaultFullName @(title : 'Name');
    email           @(title : 'e-Mail');
    division        @(title : 'Division');
    department      @(title : 'Department');
    title           @(title : 'Title');
}

annotate service.SFSF_User @(Capabilities : {
    SearchRestrictions : {
        $Type      : 'Capabilities.SearchRestrictionsType',
        Searchable : false
    },
    Insertable         : false,
    Deletable          : false,
    Updatable          : false
});

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the Role Entity
//
annotate service.Role with {
    ID   @Common : {
        Text            : name,
        TextArrangement : #TextOnly
    }    @title :  'Role ID';
    name @title  : 'Role'
}

annotate service.Role @(Capabilities : {
    Insertable : false,
    Deletable  : false,
    Updatable  : false
});

////////////////////////////////////////////////////////////////////////////
//
// UI annotations for the Status Entity
//
annotate service.Status with {
    ID   @Common : {
        Text            : name,
        TextArrangement : #TextOnly
    }    @title :  'Status ID';
    name @title  : 'Status'
}

annotate service.Status @(Capabilities : {
    Insertable : false,
    Deletable  : false,
    Updatable  : false
});
