/**
 * @private
 */
function loadBIMServerMetaModel(viewer, modelId, poid, roid, schema, bimServerClientModel) {

    function isArray(value) {
        return Object.prototype.toString.call(value) === "[object Array]";
    }

    return new Promise(function (resolve, reject) {

        if (schema == "ifc2x3tc1") {
            var query = {
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
                        type: {
                            name: "IfcRepresentation",
                            includeAllSubTypes: true
                        }
                    },
                    {
                        type: {
                            name: "IfcProductRepresentation",
                            includeAllSubTypes: true
                        }
                    },
                    {
                        type: "IfcPresentationLayerWithStyle"
                    },
                    {
                        type: {
                            name: "IfcProduct",
                            includeAllSubTypes: true
                        }
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
        } else if (schema == "ifc4") {
            var query = {
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
                            type: "IfcRelAggregates",
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
                        type: {
                            name: "IfcRepresentation",
                            includeAllSubTypes: true
                        }
                    },
                    {
                        type: {
                            name: "IfcProductRepresentation",
                            includeAllSubTypes: true
                        }
                    },
                    {
                        type: "IfcPresentationLayerWithStyle"
                    },
                    {
                        type: {
                            name: "IfcProduct",
                            includeAllSubTypes: true
                        },
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
        } else {
            console.error("IFC Schema [" + schema + "] not implemented.")
            return false;
        }
        
        bimServerClientModel.query(query, function () {
        }).done(function () {

            const entityCardinalities = { // Parent-child cardinalities for objects
                'IfcRelDecomposes': 1,
                'IfcRelAggregates': 1,
                'IfcRelContainedInSpatialStructure': 1,
                'IfcRelFillsElement': 1,
                'IfcRelVoidsElement': 1
            };

            const clientObjectMap = {}; // Create a mapping from id->instance
            const clientObjectList = [];

            for (let clientObjectId in bimServerClientModel.objects) { // The root node in a dojo store should have its parent set to null, not just something that evaluates to false
                const clientObject = bimServerClientModel.objects[clientObjectId].object;
                clientObject.parent = null;
                clientObjectMap[clientObject._i] = clientObject;
                clientObjectList.push(clientObject);
            }

            const relationships = clientObjectList.filter(function (clientObject) { // Filter all instances based on relationship objects
                return entityCardinalities[clientObject._t];
            });

            const parents = relationships.map(function (clientObject) { // Construct a tuple of {parent, child} ids
                const keys = Object.keys(clientObject);
                const related = keys.filter(function (key) {
                    return key.indexOf("Related") !== -1;
                });
                const relating = keys.filter(function (key) {
                    return key.indexOf("Relating") !== -1;
                });
                return [clientObject[relating[0]], clientObject[related[0]]];
            });

            const data = [];
            const visited = {};

            parents.forEach(function (a) {
                const ps = isArray(a[0]) ? a[0] : [a[0]]; // Relationships in IFC can be one to one/many
                const cs = isArray(a[1]) ? a[1] : [a[1]];
                for (let i = 0; i < ps.length; ++i) {
                    for (let j = 0; j < cs.length; ++j) {
                        const parentClientObject = clientObjectMap[ps[i]._i]; // Look up the instance ids in the mapping
                        const child = clientObjectMap[cs[j]._i];
                        child.parent = parentClientObject.id = parentClientObject._i; // parent, id, hasChildren are significant attributes in a dojo store
                        child.id = child._i;
                        parentClientObject.hasChildren = true;
                        if (!visited[child.id]) { // Make sure to only add instances once
                            data.push(child);
                        }
                        if (!visited[parentClientObject.id]) {
                            data.push(parentClientObject);
                        }
                        visited[parentClientObject.id] = visited[child.id] = true;
                    }
                }
            });

            const metaObjects = data.map(function (clientObject) {
                var metaObjectCfg = {
                    id: clientObject.GlobalId,
                    name: clientObject.Name,
                    type: clientObject._t,
                    external: {
                        extId: clientObject.id,
                    }
                };
                if (clientObject.parent !== undefined && clientObject.parent !== null) {
                    let clientObjectParent = clientObjectMap[clientObject.parent];
                    if (clientObjectParent) {
                        metaObjectCfg.parent = clientObjectParent.GlobalId;
                    }
                }
                if (clientObject._rgeometry !== null && clientObject._rgeometry !== undefined) {
                    metaObjectCfg.external.gid = clientObject._rgeometry._i
                }
                if (clientObject.hasChildren) {
                    metaObjectCfg.children = [];
                }
                return metaObjectCfg;
            });

            const modelMetadata = {
                id: modelId,
                revisionId: roid,
                projectId: poid,
                metaObjects: metaObjects
            };

            var metaModel = viewer.metaScene.createMetaModel(modelId, modelMetadata);

              // console.log(JSON.stringify(modelMetadata, null, "\t"));

            resolve(metaModel);
        });
    });
}

export {loadBIMServerMetaModel};
