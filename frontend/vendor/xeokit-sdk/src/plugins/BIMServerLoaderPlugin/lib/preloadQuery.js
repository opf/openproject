/**
 * @private
 */
const preloadQuery = {
    defines: {
        Representation: {
            type: "IfcProduct",
            fields: ["Representation", "geometry"]
        },
        ContainsElementsDefine: {
            type: "IfcSpatialStructureElement",
            field: "ContainsElements",
            include: {
                type: "IfcRelContainedInSpatialStructure",
                field: "RelatedElements",
                includes: [
                    "IsDecomposedByDefine",
                    "ContainsElementsDefine",
                    "Representation"
                ]
            }
        },
        IsDecomposedByDefine: {
            type: "IfcObjectDefinition",
            field: "IsDecomposedBy",
            include: {
                type: "IfcRelDecomposes",
                field: "RelatedObjects",
                includes: [
                    "IsDecomposedByDefine",
                    "ContainsElementsDefine",
                    "Representation"
                ]
            }
        }
    },
    queries: [
        {
            type: "IfcProject",
            includes: [
                "IsDecomposedByDefine",
                "ContainsElementsDefine"
            ]
        },
        {
            type: "IfcRepresentation",
            includeAllSubtypes: true
        },
        {
            type: "IfcProductRepresentation"
        },
        {
            type: "IfcPresentationLayerWithStyle"
        },
        {
            type: "IfcProduct",
            includeAllSubtypes: true
        },
        {
            type: "IfcProductDefinitionShape"
        },
        {
            type: "IfcPresentationLayerAssignment"
        },
        {
            type: "IfcRelAssociatesClassification",
            includes: [
                {
                    type: "IfcRelAssociatesClassification",
                    field: "RelatedObjects"
                },
                {
                    type: "IfcRelAssociatesClassification",
                    field: "RelatingClassification"
                }
            ]
        },
        {
            type: "IfcSIUnit"
        },
        {
            type: "IfcPresentationLayerAssignment"
        }
    ]
};


export {preloadQuery};