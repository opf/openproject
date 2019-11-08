/**
 * @private
 */
export const ifc4 = {
		  "classes": {
			    "Tristate": {},
			    "IfcActionRequest": {
			      "domain": "ifcsharedmgmtelements",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Status": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcActor": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObject"
			      ],
			      "fields": {
			        "TheActor": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "IsActingUpon": {
			          "type": "IfcRelAssignsToActor",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcActorRole": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Role": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedRole": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReference": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcActuator": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcActuatorType": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAddress": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcObjectReferenceSelect"
			      ],
			      "fields": {
			        "Purpose": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedPurpose": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OfPerson": {
			          "type": "IfcPerson",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "OfOrganization": {
			          "type": "IfcOrganization",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcAdvancedBrep": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcManifoldSolidBrep"
			      ],
			      "fields": {}
			    },
			    "IfcAdvancedBrepWithVoids": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcAdvancedBrep"
			      ],
			      "fields": {
			        "Voids": {
			          "type": "IfcClosedShell",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAdvancedFace": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcFaceSurface"
			      ],
			      "fields": {}
			    },
			    "IfcAirTerminal": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAirTerminalBox": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAirTerminalBoxType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAirTerminalType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAirToAirHeatRecovery": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAirToAirHeatRecoveryType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAlarm": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAlarmType": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAnnotation": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcProduct"
			      ],
			      "fields": {
			        "ContainedInStructure": {
			          "type": "IfcRelContainedInSpatialStructure",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcAnnotationFillArea": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "OuterBoundary": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "InnerBoundaries": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcApplication": {
			      "domain": "ifcutilityresource",
			      "superclasses": [],
			      "fields": {
			        "ApplicationDeveloper": {
			          "type": "IfcOrganization",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Version": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ApplicationFullName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ApplicationIdentifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAppliedValue": {
			      "domain": "ifccostresource",
			      "superclasses": [
			        "IfcMetricValueSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AppliedValue": {
			          "type": "IfcAppliedValueSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "UnitBasis": {
			          "type": "IfcMeasureWithUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ApplicableDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FixedUntilDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Category": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Condition": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ArithmeticOperator": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Components": {
			          "type": "IfcAppliedValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "HasExternalReference": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcApproval": {
			      "domain": "ifcapprovalresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Identifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TimeOfApproval": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Status": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Level": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Qualifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RequestingApproval": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "GivingApproval": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReferences": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ApprovedObjects": {
			          "type": "IfcRelAssociatesApproval",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ApprovedResources": {
			          "type": "IfcResourceApprovalRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsRelatedWith": {
			          "type": "IfcApprovalRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Relates": {
			          "type": "IfcApprovalRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcApprovalRelationship": {
			      "domain": "ifcapprovalresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingApproval": {
			          "type": "IfcApproval",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedApprovals": {
			          "type": "IfcApproval",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcArbitraryClosedProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcProfileDef"
			      ],
			      "fields": {
			        "OuterCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcArbitraryOpenProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcProfileDef"
			      ],
			      "fields": {
			        "Curve": {
			          "type": "IfcBoundedCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcArbitraryProfileDefWithVoids": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcArbitraryClosedProfileDef"
			      ],
			      "fields": {
			        "InnerCurves": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAsset": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcGroup"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OriginalValue": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CurrentValue": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TotalReplacementCost": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Owner": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "User": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ResponsiblePerson": {
			          "type": "IfcPerson",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "IncorporationDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepreciatedValue": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAsymmetricIShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "BottomFlangeWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeFilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeFilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeFilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeFilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeEdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeEdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomFlangeSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeEdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeEdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopFlangeSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAudioVisualAppliance": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAudioVisualApplianceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAxis1Placement": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcPlacement"
			      ],
			      "fields": {
			        "Axis": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAxis2Placement2D": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcPlacement",
			        "IfcAxis2Placement"
			      ],
			      "fields": {
			        "RefDirection": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAxis2Placement3D": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcPlacement",
			        "IfcAxis2Placement"
			      ],
			      "fields": {
			        "Axis": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RefDirection": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBSplineCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedCurve"
			      ],
			      "fields": {
			        "Degree": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ControlPointsList": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "CurveForm": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ClosedCurve": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SelfIntersect": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UpperIndexOnControlPoints": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBSplineCurveWithKnots": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBSplineCurve"
			      ],
			      "fields": {
			        "KnotMultiplicities": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "Knots": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "KnotsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "KnotSpec": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UpperIndexOnKnots": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBSplineSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedSurface"
			      ],
			      "fields": {
			        "UDegree": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "VDegree": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ControlPointsList": {
			          "type": "ListOfIfcCartesianPoint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "SurfaceForm": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UClosed": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "VClosed": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SelfIntersect": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UUpper": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "VUpper": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBSplineSurfaceWithKnots": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBSplineSurface"
			      ],
			      "fields": {
			        "UMultiplicities": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "VMultiplicities": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "UKnots": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "UKnotsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "VKnots": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "VKnotsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "KnotSpec": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "KnotVUpper": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "KnotUUpper": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBeam": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBeamStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBeam"
			      ],
			      "fields": {}
			    },
			    "IfcBeamType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBlobTexture": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcSurfaceTexture"
			      ],
			      "fields": {
			        "RasterFormat": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RasterCode": {
			          "type": "bytearray",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBlock": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCsgPrimitive3D"
			      ],
			      "fields": {
			        "XLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ZLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ZLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoiler": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoilerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBooleanClippingResult": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcBooleanResult"
			      ],
			      "fields": {}
			    },
			    "IfcBooleanResult": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcBooleanOperand",
			        "IfcCsgSelect"
			      ],
			      "fields": {
			        "Operator": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FirstOperand": {
			          "type": "IfcBooleanOperand",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SecondOperand": {
			          "type": "IfcBooleanOperand",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoundaryCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoundaryCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCompositeCurveOnSurface"
			      ],
			      "fields": {}
			    },
			    "IfcBoundaryEdgeCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcBoundaryCondition"
			      ],
			      "fields": {
			        "TranslationalStiffnessByLengthX": {
			          "type": "IfcModulusOfTranslationalSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TranslationalStiffnessByLengthY": {
			          "type": "IfcModulusOfTranslationalSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TranslationalStiffnessByLengthZ": {
			          "type": "IfcModulusOfTranslationalSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalStiffnessByLengthX": {
			          "type": "IfcModulusOfRotationalSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalStiffnessByLengthY": {
			          "type": "IfcModulusOfRotationalSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalStiffnessByLengthZ": {
			          "type": "IfcModulusOfRotationalSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoundaryFaceCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcBoundaryCondition"
			      ],
			      "fields": {
			        "TranslationalStiffnessByAreaX": {
			          "type": "IfcModulusOfSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TranslationalStiffnessByAreaY": {
			          "type": "IfcModulusOfSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TranslationalStiffnessByAreaZ": {
			          "type": "IfcModulusOfSubgradeReactionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoundaryNodeCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcBoundaryCondition"
			      ],
			      "fields": {
			        "TranslationalStiffnessX": {
			          "type": "IfcTranslationalStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TranslationalStiffnessY": {
			          "type": "IfcTranslationalStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TranslationalStiffnessZ": {
			          "type": "IfcTranslationalStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalStiffnessX": {
			          "type": "IfcRotationalStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalStiffnessY": {
			          "type": "IfcRotationalStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalStiffnessZ": {
			          "type": "IfcRotationalStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoundaryNodeConditionWarping": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcBoundaryNodeCondition"
			      ],
			      "fields": {
			        "WarpingStiffness": {
			          "type": "IfcWarpingStiffnessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoundedCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve",
			        "IfcCurveOrEdgeCurve"
			      ],
			      "fields": {}
			    },
			    "IfcBoundedSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSurface"
			      ],
			      "fields": {}
			    },
			    "IfcBoundingBox": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Corner": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "XDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ZDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ZDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoxedHalfSpace": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcHalfSpaceSolid"
			      ],
			      "fields": {
			        "Enclosure": {
			          "type": "IfcBoundingBox",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuilding": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialStructureElement"
			      ],
			      "fields": {
			        "ElevationOfRefHeight": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElevationOfRefHeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElevationOfTerrain": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElevationOfTerrainAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BuildingAddress": {
			          "type": "IfcPostalAddress",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuildingElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {}
			    },
			    "IfcBuildingElementPart": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponent"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuildingElementPartType": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuildingElementProxy": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuildingElementProxyType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuildingElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {}
			    },
			    "IfcBuildingStorey": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialStructureElement"
			      ],
			      "fields": {
			        "Elevation": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElevationAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBuildingSystem": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcSystem"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBurner": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBurnerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Width": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WallThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WallThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Girth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "GirthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InternalFilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InternalFilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableCarrierFitting": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowFitting"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableCarrierFittingType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowFittingType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableCarrierSegment": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowSegment"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableCarrierSegmentType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowSegmentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableFitting": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowFitting"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableFittingType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowFittingType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableSegment": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowSegment"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCableSegmentType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowSegmentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianPoint": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcPoint",
			        "IfcTrimmingSelect"
			      ],
			      "fields": {
			        "Coordinates": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "CoordinatesAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianPointList": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianPointList2D": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCartesianPointList"
			      ],
			      "fields": {
			        "CoordList": {
			          "type": "ListOfIfcCartesianPoint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianPointList3D": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCartesianPointList"
			      ],
			      "fields": {
			        "CoordList": {
			          "type": "ListOfIfcLengthMeasure",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianTransformationOperator": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Axis1": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Axis2": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LocalOrigin": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Scale": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScaleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SclAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianTransformationOperator2D": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCartesianTransformationOperator"
			      ],
			      "fields": {}
			    },
			    "IfcCartesianTransformationOperator2DnonUniform": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCartesianTransformationOperator2D"
			      ],
			      "fields": {
			        "Scale2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scale2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianTransformationOperator3D": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCartesianTransformationOperator"
			      ],
			      "fields": {
			        "Axis3": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCartesianTransformationOperator3DnonUniform": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCartesianTransformationOperator3D"
			      ],
			      "fields": {
			        "Scale2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scale2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scale3": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scale3AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl3": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl3AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scl2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCenterLineProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcArbitraryOpenProfileDef"
			      ],
			      "fields": {
			        "Thickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcChiller": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcChillerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcChimney": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcChimneyType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCircle": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcConic"
			      ],
			      "fields": {
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCircleHollowProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcCircleProfileDef"
			      ],
			      "fields": {
			        "WallThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WallThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCircleProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCivilElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {}
			    },
			    "IfcCivilElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {}
			    },
			    "IfcClassification": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcExternalInformation",
			        "IfcClassificationReferenceSelect",
			        "IfcClassificationSelect"
			      ],
			      "fields": {
			        "Source": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Edition": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EditionDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Location": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceTokens": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "ClassificationForObjects": {
			          "type": "IfcRelAssociatesClassification",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasReferences": {
			          "type": "IfcClassificationReference",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcClassificationReference": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcExternalReference",
			        "IfcClassificationReferenceSelect",
			        "IfcClassificationSelect"
			      ],
			      "fields": {
			        "ReferencedSource": {
			          "type": "IfcClassificationReferenceSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Sort": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ClassificationRefForObjects": {
			          "type": "IfcRelAssociatesClassification",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasReferences": {
			          "type": "IfcClassificationReference",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcClosedShell": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcConnectedFaceSet",
			        "IfcShell",
			        "IfcSolidOrShell"
			      ],
			      "fields": {}
			    },
			    "IfcCoil": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCoilType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcColourRgb": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcColourSpecification",
			        "IfcColourOrFactor"
			      ],
			      "fields": {
			        "Red": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RedAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Green": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "GreenAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Blue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BlueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcColourRgbList": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "ColourList": {
			          "type": "ListOfIfcNormalisedRatioMeasure",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcColourSpecification": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcColour"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcColumn": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcColumnStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcColumn"
			      ],
			      "fields": {}
			    },
			    "IfcColumnType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCommunicationsAppliance": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCommunicationsApplianceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcComplexProperty": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcProperty"
			      ],
			      "fields": {
			        "UsageName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasProperties": {
			          "type": "IfcProperty",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcComplexPropertyTemplate": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertyTemplate"
			      ],
			      "fields": {
			        "UsageName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TemplateType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasPropertyTemplates": {
			          "type": "IfcPropertyTemplate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcCompositeCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedCurve"
			      ],
			      "fields": {
			        "Segments": {
			          "type": "IfcCompositeCurveSegment",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "SelfIntersect": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ClosedCurve": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NSegments": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCompositeCurveOnSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCompositeCurve",
			        "IfcCurveOnSurface"
			      ],
			      "fields": {}
			    },
			    "IfcCompositeCurveSegment": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Transition": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SameSense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ParentCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "UsingCurves": {
			          "type": "IfcCompositeCurve",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCompositeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcProfileDef"
			      ],
			      "fields": {
			        "Profiles": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Label": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCompressor": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowMovingDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCompressorType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowMovingDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCondenser": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCondenserType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConic": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcAxis2Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConnectedFaceSet": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {
			        "CfsFaces": {
			          "type": "IfcFace",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConnectionCurveGeometry": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcConnectionGeometry"
			      ],
			      "fields": {
			        "CurveOnRelatingElement": {
			          "type": "IfcCurveOrEdgeCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CurveOnRelatedElement": {
			          "type": "IfcCurveOrEdgeCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConnectionGeometry": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcConnectionPointEccentricity": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcConnectionPointGeometry"
			      ],
			      "fields": {
			        "EccentricityInX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EccentricityInXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EccentricityInY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EccentricityInYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EccentricityInZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EccentricityInZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConnectionPointGeometry": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcConnectionGeometry"
			      ],
			      "fields": {
			        "PointOnRelatingElement": {
			          "type": "IfcPointOrVertexPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PointOnRelatedElement": {
			          "type": "IfcPointOrVertexPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConnectionSurfaceGeometry": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcConnectionGeometry"
			      ],
			      "fields": {
			        "SurfaceOnRelatingElement": {
			          "type": "IfcSurfaceOrFaceSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SurfaceOnRelatedElement": {
			          "type": "IfcSurfaceOrFaceSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConnectionVolumeGeometry": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcConnectionGeometry"
			      ],
			      "fields": {
			        "VolumeOnRelatingElement": {
			          "type": "IfcSolidOrShell",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "VolumeOnRelatedElement": {
			          "type": "IfcSolidOrShell",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstraint": {
			      "domain": "ifcconstraintresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConstraintGrade": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConstraintSource": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CreatingActor": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CreationTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedGrade": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReferences": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PropertiesForConstraint": {
			          "type": "IfcResourceConstraintRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcConstructionEquipmentResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResource"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionEquipmentResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResourceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionMaterialResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResource"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionMaterialResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResourceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionProductResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResource"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionProductResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResourceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcResource"
			      ],
			      "fields": {
			        "Usage": {
			          "type": "IfcResourceTime",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "BaseCosts": {
			          "type": "IfcAppliedValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "BaseQuantity": {
			          "type": "IfcPhysicalQuantity",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConstructionResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcTypeResource"
			      ],
			      "fields": {
			        "BaseCosts": {
			          "type": "IfcAppliedValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "BaseQuantity": {
			          "type": "IfcPhysicalQuantity",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcContext": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObjectDefinition"
			      ],
			      "fields": {
			        "ObjectType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Phase": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RepresentationContexts": {
			          "type": "IfcRepresentationContext",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "UnitsInContext": {
			          "type": "IfcUnitAssignment",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "IsDefinedBy": {
			          "type": "IfcRelDefinesByProperties",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Declares": {
			          "type": "IfcRelDeclares",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcContextDependentUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcNamedUnit",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReference": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcControl": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObject"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Controls": {
			          "type": "IfcRelAssignsToControl",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcController": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcControllerType": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcConversionBasedUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcNamedUnit",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConversionFactor": {
			          "type": "IfcMeasureWithUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReference": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcConversionBasedUnitWithOffset": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcConversionBasedUnit"
			      ],
			      "fields": {
			        "ConversionOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConversionOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCooledBeam": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCooledBeamType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCoolingTower": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCoolingTowerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCoordinateOperation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [],
			      "fields": {
			        "SourceCRS": {
			          "type": "IfcCoordinateReferenceSystemSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "TargetCRS": {
			          "type": "IfcCoordinateReferenceSystem",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCoordinateReferenceSystem": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcCoordinateReferenceSystemSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "GeodeticDatum": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "VerticalDatum": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasCoordinateOperation": {
			          "type": "IfcCoordinateOperation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcCostItem": {
			      "domain": "ifcsharedmgmtelements",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CostValues": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "CostQuantities": {
			          "type": "IfcPhysicalQuantity",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCostSchedule": {
			      "domain": "ifcsharedmgmtelements",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Status": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SubmittedOn": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UpdateDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCostValue": {
			      "domain": "ifccostresource",
			      "superclasses": [
			        "IfcAppliedValue"
			      ],
			      "fields": {}
			    },
			    "IfcCovering": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CoversSpaces": {
			          "type": "IfcRelCoversSpaces",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "CoversElements": {
			          "type": "IfcRelCoversBldgElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcCoveringType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCrewResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResource"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCrewResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResourceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCsgPrimitive3D": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcBooleanOperand",
			        "IfcCsgSelect"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCsgSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSolidModel"
			      ],
			      "fields": {
			        "TreeRootExpression": {
			          "type": "IfcCsgSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurrencyRelationship": {
			      "domain": "ifccostresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingMonetaryUnit": {
			          "type": "IfcMonetaryUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RelatedMonetaryUnit": {
			          "type": "IfcMonetaryUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ExchangeRate": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ExchangeRateAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RateDateTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RateSource": {
			          "type": "IfcLibraryInformation",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurtainWall": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurtainWallType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcGeometricSetSelect"
			      ],
			      "fields": {
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurveBoundedPlane": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedSurface"
			      ],
			      "fields": {
			        "BasisSurface": {
			          "type": "IfcPlane",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "OuterBoundary": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "InnerBoundaries": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurveBoundedSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedSurface"
			      ],
			      "fields": {
			        "BasisSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Boundaries": {
			          "type": "IfcBoundaryCurve",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "ImplicitOuter": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurveStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationStyle",
			        "IfcPresentationStyleSelect"
			      ],
			      "fields": {
			        "CurveFont": {
			          "type": "IfcCurveFontOrScaledCurveFontSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CurveWidth": {
			          "type": "IfcSizeSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CurveColour": {
			          "type": "IfcColour",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ModelOrDraughting": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurveStyleFont": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcCurveStyleFontSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PatternList": {
			          "type": "IfcCurveStyleFontPattern",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurveStyleFontAndScaling": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcCurveFontOrScaledCurveFontSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CurveFont": {
			          "type": "IfcCurveStyleFontSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CurveFontScaling": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CurveFontScalingAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurveStyleFontPattern": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "VisibleSegmentLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "VisibleSegmentLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InvisibleSegmentLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InvisibleSegmentLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCylindricalSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcElementarySurface"
			      ],
			      "fields": {
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDamper": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDamperType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDerivedProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcProfileDef"
			      ],
			      "fields": {
			        "ParentProfile": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Operator": {
			          "type": "IfcCartesianTransformationOperator2D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Label": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDerivedUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcUnit"
			      ],
			      "fields": {
			        "Elements": {
			          "type": "IfcDerivedUnitElement",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "UnitType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDerivedUnitElement": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [],
			      "fields": {
			        "Unit": {
			          "type": "IfcNamedUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Exponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDimensionalExponents": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [],
			      "fields": {
			        "LengthExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MassExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TimeExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElectricCurrentExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThermodynamicTemperatureExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AmountOfSubstanceExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LuminousIntensityExponent": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDirection": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcGridPlacementDirectionSelect",
			        "IfcVectorOrDirection"
			      ],
			      "fields": {
			        "DirectionRatios": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "DirectionRatiosAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDiscreteAccessory": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponent"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDiscreteAccessoryType": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDistributionChamberElement": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDistributionChamberElementType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDistributionCircuit": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionSystem"
			      ],
			      "fields": {}
			    },
			    "IfcDistributionControlElement": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionElement"
			      ],
			      "fields": {
			        "AssignedToFlowElement": {
			          "type": "IfcRelFlowControlElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcDistributionControlElementType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionElementType"
			      ],
			      "fields": {}
			    },
			    "IfcDistributionElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {
			        "HasPorts": {
			          "type": "IfcRelConnectsPortToElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcDistributionElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {}
			    },
			    "IfcDistributionFlowElement": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionElement"
			      ],
			      "fields": {
			        "HasControlElements": {
			          "type": "IfcRelFlowControlElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcDistributionFlowElementType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionElementType"
			      ],
			      "fields": {}
			    },
			    "IfcDistributionPort": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcPort"
			      ],
			      "fields": {
			        "FlowDirection": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SystemType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDistributionSystem": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcSystem"
			      ],
			      "fields": {
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDocumentInformation": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcExternalInformation",
			        "IfcDocumentSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Location": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Purpose": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IntendedUse": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scope": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Revision": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DocumentOwner": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Editors": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "CreationTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LastRevisionTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElectronicFormat": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ValidFrom": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ValidUntil": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Confidentiality": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Status": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DocumentInfoForObjects": {
			          "type": "IfcRelAssociatesDocument",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasDocumentReferences": {
			          "type": "IfcDocumentReference",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsPointedTo": {
			          "type": "IfcDocumentInformationRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsPointer": {
			          "type": "IfcDocumentInformationRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcDocumentInformationRelationship": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingDocument": {
			          "type": "IfcDocumentInformation",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedDocuments": {
			          "type": "IfcDocumentInformation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelationshipType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDocumentReference": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcExternalReference",
			        "IfcDocumentSelect"
			      ],
			      "fields": {
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferencedDocument": {
			          "type": "IfcDocumentInformation",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "DocumentRefForObjects": {
			          "type": "IfcRelAssociatesDocument",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcDoor": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "OverallHeight": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallHeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OperationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedOperationType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDoorLiningProperties": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcPreDefinedPropertySet"
			      ],
			      "fields": {
			        "LiningDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThresholdDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThresholdDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThresholdThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThresholdThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransomThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransomThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransomOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransomOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThresholdOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThresholdOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CasingThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CasingThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CasingDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CasingDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ShapeAspectStyle": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDoorPanelProperties": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcPreDefinedPropertySet"
			      ],
			      "fields": {
			        "PanelDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelOperation": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelPosition": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ShapeAspectStyle": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDoorStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcDoor"
			      ],
			      "fields": {}
			    },
			    "IfcDoorStyle": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcTypeProduct"
			      ],
			      "fields": {
			        "OperationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConstructionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ParameterTakesPrecedence": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Sizeable": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDoorType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OperationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ParameterTakesPrecedence": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedOperationType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDraughtingPreDefinedColour": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPreDefinedColour"
			      ],
			      "fields": {}
			    },
			    "IfcDraughtingPreDefinedCurveFont": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPreDefinedCurveFont"
			      ],
			      "fields": {}
			    },
			    "IfcDuctFitting": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowFitting"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDuctFittingType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowFittingType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDuctSegment": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowSegment"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDuctSegmentType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowSegmentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDuctSilencer": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTreatmentDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDuctSilencerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTreatmentDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEdge": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {
			        "EdgeStart": {
			          "type": "IfcVertex",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeEnd": {
			          "type": "IfcVertex",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEdgeCurve": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcEdge",
			        "IfcCurveOrEdgeCurve"
			      ],
			      "fields": {
			        "EdgeGeometry": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SameSense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEdgeLoop": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcLoop"
			      ],
			      "fields": {
			        "EdgeList": {
			          "type": "IfcOrientedEdge",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Ne": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricAppliance": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricApplianceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricDistributionBoard": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricDistributionBoardType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricFlowStorageDevice": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowStorageDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricFlowStorageDeviceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowStorageDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricGenerator": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricGeneratorType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricMotor": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricMotorType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricTimeControl": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricTimeControlType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcProduct",
			        "IfcStructuralActivityAssignmentSelect"
			      ],
			      "fields": {
			        "Tag": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FillsVoids": {
			          "type": "IfcRelFillsElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ConnectedTo": {
			          "type": "IfcRelConnectsElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsInterferedByElements": {
			          "type": "IfcRelInterferesElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "InterferesElements": {
			          "type": "IfcRelInterferesElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasProjections": {
			          "type": "IfcRelProjectsElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ReferencedInStructures": {
			          "type": "IfcRelReferencedInSpatialStructure",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasOpenings": {
			          "type": "IfcRelVoidsElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsConnectionRealization": {
			          "type": "IfcRelConnectsWithRealizingElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ProvidesBoundaries": {
			          "type": "IfcRelSpaceBoundary",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ConnectedFrom": {
			          "type": "IfcRelConnectsElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ContainedInStructure": {
			          "type": "IfcRelContainedInSpatialStructure",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasCoverings": {
			          "type": "IfcRelCoversBldgElements",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcElementAssembly": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {
			        "AssemblyPlace": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElementAssemblyType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElementComponent": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {}
			    },
			    "IfcElementComponentType": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {}
			    },
			    "IfcElementQuantity": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcQuantitySet"
			      ],
			      "fields": {
			        "MethodOfMeasurement": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Quantities": {
			          "type": "IfcPhysicalQuantity",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcTypeProduct"
			      ],
			      "fields": {
			        "ElementType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElementarySurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSurface"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEllipse": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcConic"
			      ],
			      "fields": {
			        "SemiAxis1": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SemiAxis1AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SemiAxis2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SemiAxis2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEllipseProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "SemiAxis1": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SemiAxis1AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SemiAxis2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SemiAxis2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEnergyConversionDevice": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcEnergyConversionDeviceType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcEngine": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEngineType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEvaporativeCooler": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEvaporativeCoolerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEvaporator": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEvaporatorType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEvent": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcProcess"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EventTriggerType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedEventTriggerType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EventOccurenceTime": {
			          "type": "IfcEventTime",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEventTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSchedulingTime"
			      ],
			      "fields": {
			        "ActualDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EarlyDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LateDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEventType": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcTypeProcess"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EventTriggerType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedEventTriggerType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcExtendedProperties": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcPropertyAbstraction"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Properties": {
			          "type": "IfcProperty",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcExternalInformation": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {}
			    },
			    "IfcExternalReference": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcLightDistributionDataSourceSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Location": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ExternalReferenceForResources": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcExternalReferenceRelationship": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingReference": {
			          "type": "IfcExternalReference",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedResourceObjects": {
			          "type": "IfcResourceObjectSelect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcExternalSpatialElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcExternalSpatialStructureElement",
			        "IfcSpaceBoundarySelect"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BoundedBy": {
			          "type": "IfcRelSpaceBoundary",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcExternalSpatialStructureElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialElement"
			      ],
			      "fields": {}
			    },
			    "IfcExternallyDefinedHatchStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcExternalReference",
			        "IfcFillStyleSelect"
			      ],
			      "fields": {}
			    },
			    "IfcExternallyDefinedSurfaceStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcExternalReference",
			        "IfcSurfaceStyleElementSelect"
			      ],
			      "fields": {}
			    },
			    "IfcExternallyDefinedTextFont": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcExternalReference",
			        "IfcTextFontSelect"
			      ],
			      "fields": {}
			    },
			    "IfcExtrudedAreaSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSweptAreaSolid"
			      ],
			      "fields": {
			        "ExtrudedDirection": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcExtrudedAreaSolidTapered": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcExtrudedAreaSolid"
			      ],
			      "fields": {
			        "EndSweptArea": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFace": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {
			        "Bounds": {
			          "type": "IfcFaceBound",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "HasTextureMaps": {
			          "type": "IfcTextureMap",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcFaceBasedSurfaceModel": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcSurfaceOrFaceSurface"
			      ],
			      "fields": {
			        "FbsmFaces": {
			          "type": "IfcConnectedFaceSet",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFaceBound": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {
			        "Bound": {
			          "type": "IfcLoop",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Orientation": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFaceOuterBound": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcFaceBound"
			      ],
			      "fields": {}
			    },
			    "IfcFaceSurface": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcFace",
			        "IfcSurfaceOrFaceSurface"
			      ],
			      "fields": {
			        "FaceSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SameSense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFacetedBrep": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcManifoldSolidBrep"
			      ],
			      "fields": {}
			    },
			    "IfcFacetedBrepWithVoids": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcFacetedBrep"
			      ],
			      "fields": {
			        "Voids": {
			          "type": "IfcClosedShell",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFailureConnectionCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralConnectionCondition"
			      ],
			      "fields": {
			        "TensionFailureX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionFailureXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionFailureY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionFailureYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionFailureZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionFailureZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompressionFailureX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompressionFailureXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompressionFailureY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompressionFailureYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompressionFailureZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompressionFailureZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFan": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowMovingDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFanType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowMovingDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFastener": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponent"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFastenerType": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFeatureElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {}
			    },
			    "IfcFeatureElementAddition": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcFeatureElement"
			      ],
			      "fields": {
			        "ProjectsElements": {
			          "type": "IfcRelProjectsElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcFeatureElementSubtraction": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcFeatureElement"
			      ],
			      "fields": {
			        "VoidsElements": {
			          "type": "IfcRelVoidsElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcFillAreaStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationStyle",
			        "IfcPresentationStyleSelect"
			      ],
			      "fields": {
			        "FillStyles": {
			          "type": "IfcFillStyleSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "ModelorDraughting": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFillAreaStyleHatching": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcFillStyleSelect"
			      ],
			      "fields": {
			        "HatchLineAppearance": {
			          "type": "IfcCurveStyle",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "StartOfNextHatchLine": {
			          "type": "IfcHatchLineDistanceSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PointOfReferenceHatchLine": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PatternStart": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "HatchLineAngle": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HatchLineAngleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFillAreaStyleTiles": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcFillStyleSelect"
			      ],
			      "fields": {
			        "TilingPattern": {
			          "type": "IfcVector",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Tiles": {
			          "type": "IfcStyledItem",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "TilingScale": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TilingScaleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFilter": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTreatmentDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFilterType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTreatmentDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFireSuppressionTerminal": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFireSuppressionTerminalType": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFixedReferenceSweptAreaSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSweptAreaSolid"
			      ],
			      "fields": {
			        "Directrix": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "StartParam": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartParamAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndParam": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndParamAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FixedReference": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFlowController": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowControllerType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFlowFitting": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowFittingType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFlowInstrument": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFlowInstrumentType": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFlowMeter": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFlowMeterType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFlowMovingDevice": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowMovingDeviceType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFlowSegment": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowSegmentType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFlowStorageDevice": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowStorageDeviceType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFlowTerminal": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowTerminalType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFlowTreatmentDevice": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElement"
			      ],
			      "fields": {}
			    },
			    "IfcFlowTreatmentDeviceType": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcDistributionFlowElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFooting": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFootingType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFurnishingElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {}
			    },
			    "IfcFurnishingElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {}
			    },
			    "IfcFurniture": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcFurnishingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFurnitureType": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcFurnishingElementType"
			      ],
			      "fields": {
			        "AssemblyPlace": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGeographicElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGeographicElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGeometricCurveSet": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricSet"
			      ],
			      "fields": {}
			    },
			    "IfcGeometricRepresentationContext": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcRepresentationContext",
			        "IfcCoordinateReferenceSystemSelect"
			      ],
			      "fields": {
			        "CoordinateSpaceDimension": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Precision": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PrecisionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WorldCoordinateSystem": {
			          "type": "IfcAxis2Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TrueNorth": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "HasSubContexts": {
			          "type": "IfcGeometricRepresentationSubContext",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasCoordinateOperation": {
			          "type": "IfcCoordinateOperation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcGeometricRepresentationItem": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcRepresentationItem"
			      ],
			      "fields": {}
			    },
			    "IfcGeometricRepresentationSubContext": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcGeometricRepresentationContext"
			      ],
			      "fields": {
			        "ParentContext": {
			          "type": "IfcGeometricRepresentationContext",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "TargetScale": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TargetScaleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TargetView": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedTargetView": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGeometricSet": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Elements": {
			          "type": "IfcGeometricSetSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGrid": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcProduct"
			      ],
			      "fields": {
			        "UAxes": {
			          "type": "IfcGridAxis",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "VAxes": {
			          "type": "IfcGridAxis",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "WAxes": {
			          "type": "IfcGridAxis",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ContainedInStructure": {
			          "type": "IfcRelContainedInSpatialStructure",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcGridAxis": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {
			        "AxisTag": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AxisCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SameSense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PartOfW": {
			          "type": "IfcGrid",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PartOfV": {
			          "type": "IfcGrid",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PartOfU": {
			          "type": "IfcGrid",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasIntersections": {
			          "type": "IfcVirtualGridIntersection",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcGridPlacement": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcObjectPlacement"
			      ],
			      "fields": {
			        "PlacementLocation": {
			          "type": "IfcVirtualGridIntersection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PlacementRefDirection": {
			          "type": "IfcGridPlacementDirectionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGroup": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObject"
			      ],
			      "fields": {
			        "IsGroupedBy": {
			          "type": "IfcRelAssignsToGroup",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcHalfSpaceSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcBooleanOperand"
			      ],
			      "fields": {
			        "BaseSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "AgreementFlag": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcHeatExchanger": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcHeatExchangerType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcHumidifier": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcHumidifierType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "OverallWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeEdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeEdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcImageTexture": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcSurfaceTexture"
			      ],
			      "fields": {
			        "URLReference": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIndexedColourMap": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "MappedTo": {
			          "type": "IfcTessellatedFaceSet",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Opacity": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OpacityAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Colours": {
			          "type": "IfcColourRgbList",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ColourIndex": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIndexedPolyCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedCurve"
			      ],
			      "fields": {
			        "Points": {
			          "type": "IfcCartesianPointList",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Segments": {
			          "type": "IfcSegmentIndexSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "SelfIntersect": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIndexedPolygonalFace": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcTessellatedItem"
			      ],
			      "fields": {
			        "CoordIndex": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "ToFaceSet": {
			          "type": "IfcPolygonalFaceSet",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcIndexedPolygonalFaceWithVoids": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcIndexedPolygonalFace"
			      ],
			      "fields": {
			        "InnerCoordIndices": {
			          "type": "ListOfELong",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIndexedTextureMap": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcTextureCoordinate"
			      ],
			      "fields": {
			        "MappedTo": {
			          "type": "IfcTessellatedFaceSet",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "TexCoords": {
			          "type": "IfcTextureVertexList",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIndexedTriangleTextureMap": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcIndexedTextureMap"
			      ],
			      "fields": {
			        "TexCoordIndex": {
			          "type": "ListOfELong",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcInterceptor": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTreatmentDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcInterceptorType": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTreatmentDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIntersectionCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSurfaceCurve"
			      ],
			      "fields": {}
			    },
			    "IfcInventory": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcGroup"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Jurisdiction": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ResponsiblePersons": {
			          "type": "IfcPerson",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "LastUpdateDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CurrentValue": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "OriginalValue": {
			          "type": "IfcCostValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIrregularTimeSeries": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcTimeSeries"
			      ],
			      "fields": {
			        "Values": {
			          "type": "IfcIrregularTimeSeriesValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIrregularTimeSeriesValue": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "TimeStamp": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ListValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcJunctionBox": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowFitting"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcJunctionBoxType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowFittingType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Width": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Thickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LegSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LegSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLaborResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResource"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLaborResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResourceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLagTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSchedulingTime"
			      ],
			      "fields": {
			        "LagValue": {
			          "type": "IfcTimeOrRatioSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "DurationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLamp": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLampType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLibraryInformation": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcExternalInformation",
			        "IfcLibrarySelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Version": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Publisher": {
			          "type": "IfcActorSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "VersionDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Location": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LibraryInfoForObjects": {
			          "type": "IfcRelAssociatesLibrary",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasLibraryReferences": {
			          "type": "IfcLibraryReference",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcLibraryReference": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcExternalReference",
			        "IfcLibrarySelect"
			      ],
			      "fields": {
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Language": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferencedLibrary": {
			          "type": "IfcLibraryInformation",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "LibraryRefForObjects": {
			          "type": "IfcRelAssociatesLibrary",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcLightDistributionData": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [],
			      "fields": {
			        "MainPlaneAngle": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MainPlaneAngleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SecondaryPlaneAngle": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "SecondaryPlaneAngleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "LuminousIntensity": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "LuminousIntensityAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightFixture": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightFixtureType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightIntensityDistribution": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcLightDistributionDataSourceSelect"
			      ],
			      "fields": {
			        "LightDistributionCurve": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DistributionData": {
			          "type": "IfcLightDistributionData",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightSource": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LightColour": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "AmbientIntensity": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AmbientIntensityAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Intensity": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IntensityAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightSourceAmbient": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcLightSource"
			      ],
			      "fields": {}
			    },
			    "IfcLightSourceDirectional": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcLightSource"
			      ],
			      "fields": {
			        "Orientation": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightSourceGoniometric": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcLightSource"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ColourAppearance": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ColourTemperature": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ColourTemperatureAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LuminousFlux": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LuminousFluxAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LightEmissionSource": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LightDistributionDataSource": {
			          "type": "IfcLightDistributionDataSourceSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightSourcePositional": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcLightSource"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConstantAttenuation": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConstantAttenuationAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DistanceAttenuation": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DistanceAttenuationAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "QuadricAttenuation": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "QuadricAttenuationAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLightSourceSpot": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcLightSourcePositional"
			      ],
			      "fields": {
			        "Orientation": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ConcentrationExponent": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConcentrationExponentAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SpreadAngle": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SpreadAngleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BeamWidthAngle": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BeamWidthAngleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLine": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve"
			      ],
			      "fields": {
			        "Pnt": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Dir": {
			          "type": "IfcVector",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLocalPlacement": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcObjectPlacement"
			      ],
			      "fields": {
			        "PlacementRelTo": {
			          "type": "IfcObjectPlacement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelativePlacement": {
			          "type": "IfcAxis2Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLoop": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {}
			    },
			    "IfcManifoldSolidBrep": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSolidModel"
			      ],
			      "fields": {
			        "Outer": {
			          "type": "IfcClosedShell",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMapConversion": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcCoordinateOperation"
			      ],
			      "fields": {
			        "Eastings": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EastingsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Northings": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NorthingsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OrthogonalHeight": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OrthogonalHeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XAxisAbscissa": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XAxisAbscissaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XAxisOrdinate": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XAxisOrdinateAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Scale": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScaleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMappedItem": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcRepresentationItem"
			      ],
			      "fields": {
			        "MappingSource": {
			          "type": "IfcRepresentationMap",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "MappingTarget": {
			          "type": "IfcCartesianTransformationOperator",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterial": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Category": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasRepresentation": {
			          "type": "IfcMaterialDefinitionRepresentation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsRelatedWith": {
			          "type": "IfcMaterialRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatesTo": {
			          "type": "IfcMaterialRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialClassificationRelationship": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [],
			      "fields": {
			        "MaterialClassifications": {
			          "type": "IfcClassificationSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "ClassifiedMaterial": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialConstituent": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Material": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Fraction": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FractionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Category": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ToMaterialConstituentSet": {
			          "type": "IfcMaterialConstituentSet",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialConstituentSet": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MaterialConstituents": {
			          "type": "IfcMaterialConstituent",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialDefinition": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "AssociatedTo": {
			          "type": "IfcRelAssociatesMaterial",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasExternalReferences": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasProperties": {
			          "type": "IfcMaterialProperties",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialDefinitionRepresentation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcProductRepresentation"
			      ],
			      "fields": {
			        "RepresentedMaterial": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialLayer": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "Material": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LayerThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LayerThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IsVentilated": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Category": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Priority": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ToMaterialLayerSet": {
			          "type": "IfcMaterialLayerSet",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialLayerSet": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "MaterialLayers": {
			          "type": "IfcMaterialLayer",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "LayerSetName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TotalThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TotalThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialLayerSetUsage": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialUsageDefinition"
			      ],
			      "fields": {
			        "ForLayerSet": {
			          "type": "IfcMaterialLayerSet",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LayerSetDirection": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DirectionSense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OffsetFromReferenceLine": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OffsetFromReferenceLineAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceExtent": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceExtentAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialLayerWithOffsets": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialLayer"
			      ],
			      "fields": {
			        "OffsetDirection": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OffsetValues": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "OffsetValuesAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialList": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialSelect"
			      ],
			      "fields": {
			        "Materials": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialProfile": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Material": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Profile": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Priority": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Category": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ToMaterialProfileSet": {
			          "type": "IfcMaterialProfileSet",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialProfileSet": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialDefinition"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MaterialProfiles": {
			          "type": "IfcMaterialProfile",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "CompositeProfile": {
			          "type": "IfcCompositeProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialProfileSetUsage": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialUsageDefinition"
			      ],
			      "fields": {
			        "ForProfileSet": {
			          "type": "IfcMaterialProfileSet",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CardinalPoint": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceExtent": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceExtentAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialProfileSetUsageTapering": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialProfileSetUsage"
			      ],
			      "fields": {
			        "ForProfileEndSet": {
			          "type": "IfcMaterialProfileSet",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CardinalEndPoint": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialProfileWithOffsets": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialProfile"
			      ],
			      "fields": {
			        "OffsetValues": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "OffsetValuesAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialProperties": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcExtendedProperties"
			      ],
			      "fields": {
			        "Material": {
			          "type": "IfcMaterialDefinition",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMaterialRelationship": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingMaterial": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedMaterials": {
			          "type": "IfcMaterial",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Expression": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMaterialUsageDefinition": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [
			        "IfcMaterialSelect"
			      ],
			      "fields": {
			        "AssociatedTo": {
			          "type": "IfcRelAssociatesMaterial",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcMeasureWithUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcAppliedValueSelect",
			        "IfcMetricValueSelect"
			      ],
			      "fields": {
			        "ValueComponent": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "UnitComponent": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMechanicalFastener": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponent"
			      ],
			      "fields": {
			        "NominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMechanicalFastenerType": {
			      "domain": "ifcsharedcomponentelements",
			      "superclasses": [
			        "IfcElementComponentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMedicalDevice": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMedicalDeviceType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMember": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMemberStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcMember"
			      ],
			      "fields": {}
			    },
			    "IfcMemberType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMetric": {
			      "domain": "ifcconstraintresource",
			      "superclasses": [
			        "IfcConstraint"
			      ],
			      "fields": {
			        "Benchmark": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ValueSource": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DataValue": {
			          "type": "IfcMetricValueSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ReferencePath": {
			          "type": "IfcReference",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMirroredProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcDerivedProfileDef"
			      ],
			      "fields": {}
			    },
			    "IfcMonetaryUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcUnit"
			      ],
			      "fields": {
			        "Currency": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMotorConnection": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMotorConnectionType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcNamedUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcUnit"
			      ],
			      "fields": {
			        "Dimensions": {
			          "type": "IfcDimensionalExponents",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "UnitType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcObject": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObjectDefinition"
			      ],
			      "fields": {
			        "ObjectType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IsDeclaredBy": {
			          "type": "IfcRelDefinesByObject",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Declares": {
			          "type": "IfcRelDefinesByObject",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsTypedBy": {
			          "type": "IfcRelDefinesByType",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsDefinedBy": {
			          "type": "IfcRelDefinesByProperties",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcObjectDefinition": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRoot",
			        "IfcDefinitionSelect"
			      ],
			      "fields": {
			        "HasAssignments": {
			          "type": "IfcRelAssigns",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Nests": {
			          "type": "IfcRelNests",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsNestedBy": {
			          "type": "IfcRelNests",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasContext": {
			          "type": "IfcRelDeclares",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsDecomposedBy": {
			          "type": "IfcRelAggregates",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Decomposes": {
			          "type": "IfcRelAggregates",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasAssociations": {
			          "type": "IfcRelAssociates",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcObjectPlacement": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {
			        "PlacesObject": {
			          "type": "IfcProduct",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ReferencedByPlacements": {
			          "type": "IfcLocalPlacement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcObjective": {
			      "domain": "ifcconstraintresource",
			      "superclasses": [
			        "IfcConstraint"
			      ],
			      "fields": {
			        "BenchmarkValues": {
			          "type": "IfcConstraint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "LogicalAggregator": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ObjectiveQualifier": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedQualifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOccupant": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcActor"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOffsetCurve2D": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve"
			      ],
			      "fields": {
			        "BasisCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Distance": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DistanceAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SelfIntersect": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOffsetCurve3D": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve"
			      ],
			      "fields": {
			        "BasisCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Distance": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DistanceAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SelfIntersect": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RefDirection": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOpenShell": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcConnectedFaceSet",
			        "IfcShell"
			      ],
			      "fields": {}
			    },
			    "IfcOpeningElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcFeatureElementSubtraction"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasFillings": {
			          "type": "IfcRelFillsElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcOpeningStandardCase": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcOpeningElement"
			      ],
			      "fields": {}
			    },
			    "IfcOrganization": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcActorSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Roles": {
			          "type": "IfcActorRole",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Addresses": {
			          "type": "IfcAddress",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsRelatedBy": {
			          "type": "IfcOrganizationRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Relates": {
			          "type": "IfcOrganizationRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Engages": {
			          "type": "IfcPersonAndOrganization",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcOrganizationRelationship": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingOrganization": {
			          "type": "IfcOrganization",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedOrganizations": {
			          "type": "IfcOrganization",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcOrientedEdge": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcEdge"
			      ],
			      "fields": {
			        "EdgeElement": {
			          "type": "IfcEdge",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Orientation": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOuterBoundaryCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundaryCurve"
			      ],
			      "fields": {}
			    },
			    "IfcOutlet": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOutletType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcOwnerHistory": {
			      "domain": "ifcutilityresource",
			      "superclasses": [],
			      "fields": {
			        "OwningUser": {
			          "type": "IfcPersonAndOrganization",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "OwningApplication": {
			          "type": "IfcApplication",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "State": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ChangeAction": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LastModifiedDate": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LastModifyingUser": {
			          "type": "IfcPersonAndOrganization",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LastModifyingApplication": {
			          "type": "IfcApplication",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CreationDate": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcParameterizedProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcProfileDef"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcAxis2Placement2D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPath": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {
			        "EdgeList": {
			          "type": "IfcOrientedEdge",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPcurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve",
			        "IfcCurveOnSurface"
			      ],
			      "fields": {
			        "BasisSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPerformanceHistory": {
			      "domain": "ifccontrolextension",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "LifeCyclePhase": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPermeableCoveringProperties": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcPreDefinedPropertySet"
			      ],
			      "fields": {
			        "OperationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelPosition": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ShapeAspectStyle": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPermit": {
			      "domain": "ifcsharedmgmtelements",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Status": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPerson": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcActorSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FamilyName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "GivenName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MiddleNames": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "PrefixTitles": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "SuffixTitles": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "Roles": {
			          "type": "IfcActorRole",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Addresses": {
			          "type": "IfcAddress",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "EngagedIn": {
			          "type": "IfcPersonAndOrganization",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPersonAndOrganization": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcActorSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "ThePerson": {
			          "type": "IfcPerson",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "TheOrganization": {
			          "type": "IfcOrganization",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Roles": {
			          "type": "IfcActorRole",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPhysicalComplexQuantity": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalQuantity"
			      ],
			      "fields": {
			        "HasQuantities": {
			          "type": "IfcPhysicalQuantity",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Discrimination": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Quality": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Usage": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPhysicalQuantity": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReferences": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PartOfComplex": {
			          "type": "IfcPhysicalComplexQuantity",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPhysicalSimpleQuantity": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalQuantity"
			      ],
			      "fields": {
			        "Unit": {
			          "type": "IfcNamedUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPile": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConstructionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPileType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPipeFitting": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowFitting"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPipeFittingType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowFittingType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPipeSegment": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowSegment"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPipeSegmentType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowSegmentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPixelTexture": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcSurfaceTexture"
			      ],
			      "fields": {
			        "Width": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Height": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ColourComponents": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Pixel": {
			          "type": "bytearray",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlacement": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Location": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlanarBox": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [
			        "IfcPlanarExtent"
			      ],
			      "fields": {
			        "Placement": {
			          "type": "IfcAxis2Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlanarExtent": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "SizeInX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SizeInXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SizeInY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SizeInYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlane": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcElementarySurface"
			      ],
			      "fields": {}
			    },
			    "IfcPlate": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlateStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcPlate"
			      ],
			      "fields": {}
			    },
			    "IfcPlateType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPoint": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcGeometricSetSelect",
			        "IfcPointOrVertexPoint"
			      ],
			      "fields": {}
			    },
			    "IfcPointOnCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcPoint"
			      ],
			      "fields": {
			        "BasisCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PointParameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PointParameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPointOnSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcPoint"
			      ],
			      "fields": {
			        "BasisSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PointParameterU": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PointParameterUAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PointParameterV": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PointParameterVAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPolyLoop": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcLoop"
			      ],
			      "fields": {
			        "Polygon": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPolygonalBoundedHalfSpace": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcHalfSpaceSolid"
			      ],
			      "fields": {
			        "Position": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PolygonalBoundary": {
			          "type": "IfcBoundedCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPolygonalFaceSet": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcTessellatedFaceSet"
			      ],
			      "fields": {
			        "Closed": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Faces": {
			          "type": "IfcIndexedPolygonalFace",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PnIndex": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPolyline": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedCurve"
			      ],
			      "fields": {
			        "Points": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPort": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcProduct"
			      ],
			      "fields": {
			        "ContainedIn": {
			          "type": "IfcRelConnectsPortToElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ConnectedFrom": {
			          "type": "IfcRelConnectsPorts",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ConnectedTo": {
			          "type": "IfcRelConnectsPorts",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPostalAddress": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcAddress"
			      ],
			      "fields": {
			        "InternalLocation": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AddressLines": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "PostalBox": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Town": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Region": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PostalCode": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Country": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPreDefinedColour": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPreDefinedItem",
			        "IfcColour"
			      ],
			      "fields": {}
			    },
			    "IfcPreDefinedCurveFont": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPreDefinedItem",
			        "IfcCurveStyleFontSelect"
			      ],
			      "fields": {}
			    },
			    "IfcPreDefinedItem": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPreDefinedProperties": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcPropertyAbstraction"
			      ],
			      "fields": {}
			    },
			    "IfcPreDefinedPropertySet": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertySetDefinition"
			      ],
			      "fields": {}
			    },
			    "IfcPreDefinedTextFont": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPreDefinedItem",
			        "IfcTextFontSelect"
			      ],
			      "fields": {}
			    },
			    "IfcPresentationItem": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcPresentationLayerAssignment": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AssignedItems": {
			          "type": "IfcLayeredItem",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Identifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPresentationLayerWithStyle": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [
			        "IfcPresentationLayerAssignment"
			      ],
			      "fields": {
			        "LayerOn": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LayerFrozen": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LayerBlocked": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LayerStyles": {
			          "type": "IfcPresentationStyle",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPresentationStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcStyleAssignmentSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPresentationStyleAssignment": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcStyleAssignmentSelect"
			      ],
			      "fields": {
			        "Styles": {
			          "type": "IfcPresentationStyleSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProcedure": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcProcess"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProcedureType": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcTypeProcess"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProcess": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObject",
			        "IfcProcessSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IsPredecessorTo": {
			          "type": "IfcRelSequence",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsSuccessorFrom": {
			          "type": "IfcRelSequence",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "OperatesOn": {
			          "type": "IfcRelAssignsToProcess",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcProduct": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObject",
			        "IfcProductSelect"
			      ],
			      "fields": {
			        "ObjectPlacement": {
			          "type": "IfcObjectPlacement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Representation": {
			          "type": "IfcProductRepresentation",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "ReferencedBy": {
			          "type": "IfcRelAssignsToProduct",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "geometry": {
			          "type": "GeometryInfo",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProductDefinitionShape": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcProductRepresentation",
			        "IfcProductRepresentationSelect"
			      ],
			      "fields": {
			        "ShapeOfProduct": {
			          "type": "IfcProduct",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasShapeAspects": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcProductRepresentation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Representations": {
			          "type": "IfcRepresentation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "ProfileType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ProfileName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReference": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasProperties": {
			          "type": "IfcProfileProperties",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcProfileProperties": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcExtendedProperties"
			      ],
			      "fields": {
			        "ProfileDefinition": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcProject": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcContext"
			      ],
			      "fields": {}
			    },
			    "IfcProjectLibrary": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcContext"
			      ],
			      "fields": {}
			    },
			    "IfcProjectOrder": {
			      "domain": "ifcsharedmgmtelements",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Status": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProjectedCRS": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcCoordinateReferenceSystem"
			      ],
			      "fields": {
			        "MapProjection": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MapZone": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MapUnit": {
			          "type": "IfcNamedUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProjectionElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcFeatureElementAddition"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProperty": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcPropertyAbstraction"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PartOfPset": {
			          "type": "IfcPropertySet",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PropertyForDependance": {
			          "type": "IfcPropertyDependencyRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PropertyDependsOn": {
			          "type": "IfcPropertyDependencyRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PartOfComplex": {
			          "type": "IfcComplexProperty",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasConstraints": {
			          "type": "IfcResourceConstraintRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasApprovals": {
			          "type": "IfcResourceApprovalRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertyAbstraction": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "HasExternalReferences": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertyBoundedValue": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcSimpleProperty"
			      ],
			      "fields": {
			        "UpperBoundValue": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LowerBoundValue": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Unit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SetPointValue": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyDefinition": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRoot",
			        "IfcDefinitionSelect"
			      ],
			      "fields": {
			        "HasContext": {
			          "type": "IfcRelDeclares",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasAssociations": {
			          "type": "IfcRelAssociates",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertyDependencyRelationship": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "DependingProperty": {
			          "type": "IfcProperty",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "DependantProperty": {
			          "type": "IfcProperty",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Expression": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyEnumeratedValue": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcSimpleProperty"
			      ],
			      "fields": {
			        "EnumerationValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "EnumerationReference": {
			          "type": "IfcPropertyEnumeration",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyEnumeration": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcPropertyAbstraction"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EnumerationValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Unit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyListValue": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcSimpleProperty"
			      ],
			      "fields": {
			        "ListValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Unit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyReferenceValue": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcSimpleProperty"
			      ],
			      "fields": {
			        "UsageName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PropertyReference": {
			          "type": "IfcObjectReferenceSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertySet": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertySetDefinition"
			      ],
			      "fields": {
			        "HasProperties": {
			          "type": "IfcProperty",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertySetDefinition": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertyDefinition",
			        "IfcPropertySetDefinitionSelect"
			      ],
			      "fields": {
			        "DefinesType": {
			          "type": "IfcTypeObject",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "IsDefinedBy": {
			          "type": "IfcRelDefinesByTemplate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "DefinesOccurrence": {
			          "type": "IfcRelDefinesByProperties",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertySetTemplate": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertyTemplateDefinition"
			      ],
			      "fields": {
			        "TemplateType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ApplicableEntity": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasPropertyTemplates": {
			          "type": "IfcPropertyTemplate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Defines": {
			          "type": "IfcRelDefinesByTemplate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertySingleValue": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcSimpleProperty"
			      ],
			      "fields": {
			        "NominalValue": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Unit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyTableValue": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcSimpleProperty"
			      ],
			      "fields": {
			        "DefiningValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "DefinedValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Expression": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DefiningUnit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "DefinedUnit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CurveInterpolation": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPropertyTemplate": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertyTemplateDefinition"
			      ],
			      "fields": {
			        "PartOfComplexTemplate": {
			          "type": "IfcComplexPropertyTemplate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "PartOfPsetTemplate": {
			          "type": "IfcPropertySetTemplate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcPropertyTemplateDefinition": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertyDefinition"
			      ],
			      "fields": {}
			    },
			    "IfcProtectiveDevice": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProtectiveDeviceTrippingUnit": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProtectiveDeviceTrippingUnitType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProtectiveDeviceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcProxy": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcProduct"
			      ],
			      "fields": {
			        "ProxyType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Tag": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPump": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowMovingDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPumpType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowMovingDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcQuantityArea": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalSimpleQuantity"
			      ],
			      "fields": {
			        "AreaValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AreaValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Formula": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcQuantityCount": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalSimpleQuantity"
			      ],
			      "fields": {
			        "CountValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CountValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Formula": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcQuantityLength": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalSimpleQuantity"
			      ],
			      "fields": {
			        "LengthValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LengthValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Formula": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcQuantitySet": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertySetDefinition"
			      ],
			      "fields": {}
			    },
			    "IfcQuantityTime": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalSimpleQuantity"
			      ],
			      "fields": {
			        "TimeValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TimeValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Formula": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcQuantityVolume": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalSimpleQuantity"
			      ],
			      "fields": {
			        "VolumeValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "VolumeValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Formula": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcQuantityWeight": {
			      "domain": "ifcquantityresource",
			      "superclasses": [
			        "IfcPhysicalSimpleQuantity"
			      ],
			      "fields": {
			        "WeightValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WeightValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Formula": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRailing": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRailingType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRamp": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRampFlight": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRampFlightType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRampType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRationalBSplineCurveWithKnots": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBSplineCurveWithKnots"
			      ],
			      "fields": {
			        "WeightsData": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "WeightsDataAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "Weights": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WeightsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRationalBSplineSurfaceWithKnots": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBSplineSurfaceWithKnots"
			      ],
			      "fields": {
			        "WeightsData": {
			          "type": "ListOfEDouble",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Weights": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WeightsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRectangleHollowProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcRectangleProfileDef"
			      ],
			      "fields": {
			        "WallThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WallThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InnerFilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InnerFilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OuterFilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OuterFilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRectangleProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "XDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRectangularPyramid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCsgPrimitive3D"
			      ],
			      "fields": {
			        "XLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "XLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Height": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRectangularTrimmedSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedSurface"
			      ],
			      "fields": {
			        "BasisSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "U1": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "U1AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "V1": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "V1AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "U2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "U2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "V2": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "V2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Usense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Vsense": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRecurrencePattern": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "RecurrenceType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DayComponent": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "WeekdayComponent": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "MonthComponent": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "Position": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Interval": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Occurrences": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TimePeriods": {
			          "type": "IfcTimePeriod",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReference": {
			      "domain": "ifcconstraintresource",
			      "superclasses": [
			        "IfcAppliedValueSelect",
			        "IfcMetricValueSelect"
			      ],
			      "fields": {
			        "TypeIdentifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AttributeIdentifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InstanceName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ListPositions": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "InnerReference": {
			          "type": "IfcReference",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRegularTimeSeries": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcTimeSeries"
			      ],
			      "fields": {
			        "TimeStep": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TimeStepAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Values": {
			          "type": "IfcTimeSeriesValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcementBarProperties": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcPreDefinedProperties"
			      ],
			      "fields": {
			        "TotalCrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TotalCrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SteelGrade": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarSurface": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EffectiveDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EffectiveDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalBarDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalBarDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarCount": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarCountAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcementDefinitionProperties": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcPreDefinedPropertySet"
			      ],
			      "fields": {
			        "DefinitionType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReinforcementSectionDefinitions": {
			          "type": "IfcSectionReinforcementProperties",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcingBar": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElement"
			      ],
			      "fields": {
			        "NominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarSurface": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcingBarType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BarSurface": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BendingShapeCode": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BendingParameters": {
			          "type": "IfcBendingParameterSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcingElement": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcElementComponent"
			      ],
			      "fields": {
			        "SteelGrade": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcingElementType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcElementComponentType"
			      ],
			      "fields": {}
			    },
			    "IfcReinforcingMesh": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElement"
			      ],
			      "fields": {
			        "MeshLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarNominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarNominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarNominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarNominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarCrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarCrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarCrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarCrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarSpacing": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarSpacingAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarSpacing": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarSpacingAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReinforcingMeshType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MeshWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarNominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarNominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarNominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarNominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarCrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarCrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarCrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarCrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarSpacing": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalBarSpacingAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarSpacing": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransverseBarSpacingAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BendingShapeCode": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BendingParameters": {
			          "type": "IfcBendingParameterSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelAggregates": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelDecomposes"
			      ],
			      "fields": {
			        "RelatingObject": {
			          "type": "IfcObjectDefinition",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedObjects": {
			          "type": "IfcObjectDefinition",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssigns": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelationship"
			      ],
			      "fields": {
			        "RelatedObjects": {
			          "type": "IfcObjectDefinition",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatedObjectsType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelAssignsToActor": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssigns"
			      ],
			      "fields": {
			        "RelatingActor": {
			          "type": "IfcActor",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "ActingRole": {
			          "type": "IfcActorRole",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelAssignsToControl": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssigns"
			      ],
			      "fields": {
			        "RelatingControl": {
			          "type": "IfcControl",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssignsToGroup": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssigns"
			      ],
			      "fields": {
			        "RelatingGroup": {
			          "type": "IfcGroup",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssignsToGroupByFactor": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssignsToGroup"
			      ],
			      "fields": {
			        "Factor": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FactorAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelAssignsToProcess": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssigns"
			      ],
			      "fields": {
			        "RelatingProcess": {
			          "type": "IfcProcessSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "QuantityInProcess": {
			          "type": "IfcMeasureWithUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelAssignsToProduct": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssigns"
			      ],
			      "fields": {
			        "RelatingProduct": {
			          "type": "IfcProductSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssignsToResource": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssigns"
			      ],
			      "fields": {
			        "RelatingResource": {
			          "type": "IfcResourceSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssociates": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelationship"
			      ],
			      "fields": {
			        "RelatedObjects": {
			          "type": "IfcDefinitionSelect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssociatesApproval": {
			      "domain": "ifccontrolextension",
			      "superclasses": [
			        "IfcRelAssociates"
			      ],
			      "fields": {
			        "RelatingApproval": {
			          "type": "IfcApproval",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssociatesClassification": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssociates"
			      ],
			      "fields": {
			        "RelatingClassification": {
			          "type": "IfcClassificationSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssociatesConstraint": {
			      "domain": "ifccontrolextension",
			      "superclasses": [
			        "IfcRelAssociates"
			      ],
			      "fields": {
			        "Intent": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RelatingConstraint": {
			          "type": "IfcConstraint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelAssociatesDocument": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssociates"
			      ],
			      "fields": {
			        "RelatingDocument": {
			          "type": "IfcDocumentSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssociatesLibrary": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelAssociates"
			      ],
			      "fields": {
			        "RelatingLibrary": {
			          "type": "IfcLibrarySelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelAssociatesMaterial": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelAssociates"
			      ],
			      "fields": {
			        "RelatingMaterial": {
			          "type": "IfcMaterialSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelConnects": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelationship"
			      ],
			      "fields": {}
			    },
			    "IfcRelConnectsElements": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "ConnectionGeometry": {
			          "type": "IfcConnectionGeometry",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "RelatingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelConnectsPathElements": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcRelConnectsElements"
			      ],
			      "fields": {
			        "RelatingPriorities": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "RelatedPriorities": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "RelatedConnectionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RelatingConnectionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelConnectsPortToElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingPort": {
			          "type": "IfcPort",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedElement": {
			          "type": "IfcDistributionElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelConnectsPorts": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingPort": {
			          "type": "IfcPort",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedPort": {
			          "type": "IfcPort",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RealizingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelConnectsStructuralActivity": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingElement": {
			          "type": "IfcStructuralActivityAssignmentSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedStructuralActivity": {
			          "type": "IfcStructuralActivity",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelConnectsStructuralMember": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingStructuralMember": {
			          "type": "IfcStructuralMember",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedStructuralConnection": {
			          "type": "IfcStructuralConnection",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "AppliedCondition": {
			          "type": "IfcBoundaryCondition",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "AdditionalConditions": {
			          "type": "IfcStructuralConnectionCondition",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SupportedLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SupportedLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ConditionCoordinateSystem": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelConnectsWithEccentricity": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcRelConnectsStructuralMember"
			      ],
			      "fields": {
			        "ConnectionConstraint": {
			          "type": "IfcConnectionGeometry",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelConnectsWithRealizingElements": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnectsElements"
			      ],
			      "fields": {
			        "RealizingElements": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ConnectionType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelContainedInSpatialStructure": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatedElements": {
			          "type": "IfcProduct",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingStructure": {
			          "type": "IfcSpatialElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelCoversBldgElements": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingBuildingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedCoverings": {
			          "type": "IfcCovering",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelCoversSpaces": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingSpace": {
			          "type": "IfcSpace",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedCoverings": {
			          "type": "IfcCovering",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelDeclares": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelationship"
			      ],
			      "fields": {
			        "RelatingContext": {
			          "type": "IfcContext",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedDefinitions": {
			          "type": "IfcDefinitionSelect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelDecomposes": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelationship"
			      ],
			      "fields": {}
			    },
			    "IfcRelDefines": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelationship"
			      ],
			      "fields": {}
			    },
			    "IfcRelDefinesByObject": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelDefines"
			      ],
			      "fields": {
			        "RelatedObjects": {
			          "type": "IfcObject",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingObject": {
			          "type": "IfcObject",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelDefinesByProperties": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelDefines"
			      ],
			      "fields": {
			        "RelatedObjects": {
			          "type": "IfcObjectDefinition",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingPropertyDefinition": {
			          "type": "IfcPropertySetDefinitionSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelDefinesByTemplate": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelDefines"
			      ],
			      "fields": {
			        "RelatedPropertySets": {
			          "type": "IfcPropertySetDefinition",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingTemplate": {
			          "type": "IfcPropertySetTemplate",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelDefinesByType": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelDefines"
			      ],
			      "fields": {
			        "RelatedObjects": {
			          "type": "IfcObject",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingType": {
			          "type": "IfcTypeObject",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelFillsElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingOpeningElement": {
			          "type": "IfcOpeningElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedBuildingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelFlowControlElements": {
			      "domain": "ifcsharedbldgserviceelements",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatedControlElements": {
			          "type": "IfcDistributionControlElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingFlowElement": {
			          "type": "IfcDistributionFlowElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelInterferesElements": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "InterferenceGeometry": {
			          "type": "IfcConnectionGeometry",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "InterferenceType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ImpliedOrder": {
			          "type": "boolean",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelNests": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRelDecomposes"
			      ],
			      "fields": {
			        "RelatingObject": {
			          "type": "IfcObjectDefinition",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedObjects": {
			          "type": "IfcObjectDefinition",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelProjectsElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelDecomposes"
			      ],
			      "fields": {
			        "RelatingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedFeatureElement": {
			          "type": "IfcFeatureElementAddition",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelReferencedInSpatialStructure": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatedElements": {
			          "type": "IfcProduct",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingStructure": {
			          "type": "IfcSpatialElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelSequence": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingProcess": {
			          "type": "IfcProcess",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedProcess": {
			          "type": "IfcProcess",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "TimeLag": {
			          "type": "IfcLagTime",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SequenceType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedSequenceType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelServicesBuildings": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingSystem": {
			          "type": "IfcSystem",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedBuildings": {
			          "type": "IfcSpatialElement",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelSpaceBoundary": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelConnects"
			      ],
			      "fields": {
			        "RelatingSpace": {
			          "type": "IfcSpaceBoundarySelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedBuildingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "ConnectionGeometry": {
			          "type": "IfcConnectionGeometry",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PhysicalOrVirtualBoundary": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InternalOrExternalBoundary": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRelSpaceBoundary1stLevel": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelSpaceBoundary"
			      ],
			      "fields": {
			        "ParentBoundary": {
			          "type": "IfcRelSpaceBoundary1stLevel",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "InnerBoundaries": {
			          "type": "IfcRelSpaceBoundary1stLevel",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelSpaceBoundary2ndLevel": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelSpaceBoundary1stLevel"
			      ],
			      "fields": {
			        "CorrespondingBoundary": {
			          "type": "IfcRelSpaceBoundary2ndLevel",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Corresponds": {
			          "type": "IfcRelSpaceBoundary2ndLevel",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelVoidsElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcRelDecomposes"
			      ],
			      "fields": {
			        "RelatingBuildingElement": {
			          "type": "IfcElement",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedOpeningElement": {
			          "type": "IfcFeatureElementSubtraction",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRelationship": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcRoot"
			      ],
			      "fields": {}
			    },
			    "IfcReparametrisedCompositeCurveSegment": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCompositeCurveSegment"
			      ],
			      "fields": {
			        "ParamLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ParamLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRepresentation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcLayeredItem"
			      ],
			      "fields": {
			        "ContextOfItems": {
			          "type": "IfcRepresentationContext",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RepresentationIdentifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RepresentationType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Items": {
			          "type": "IfcRepresentationItem",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "RepresentationMap": {
			          "type": "IfcRepresentationMap",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "LayerAssignments": {
			          "type": "IfcPresentationLayerAssignment",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "OfProductRepresentation": {
			          "type": "IfcProductRepresentation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRepresentationContext": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [],
			      "fields": {
			        "ContextIdentifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ContextType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RepresentationsInContext": {
			          "type": "IfcRepresentation",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRepresentationItem": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcLayeredItem"
			      ],
			      "fields": {
			        "LayerAssignment": {
			          "type": "IfcPresentationLayerAssignment",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "StyledByItem": {
			          "type": "IfcStyledItem",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcRepresentationMap": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcProductRepresentationSelect"
			      ],
			      "fields": {
			        "MappingOrigin": {
			          "type": "IfcAxis2Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "MappedRepresentation": {
			          "type": "IfcRepresentation",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "HasShapeAspects": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "MapUsage": {
			          "type": "IfcMappedItem",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcResource": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObject",
			        "IfcResourceSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ResourceOf": {
			          "type": "IfcRelAssignsToResource",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcResourceApprovalRelationship": {
			      "domain": "ifcapprovalresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatedResourceObjects": {
			          "type": "IfcResourceObjectSelect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "RelatingApproval": {
			          "type": "IfcApproval",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcResourceConstraintRelationship": {
			      "domain": "ifcconstraintresource",
			      "superclasses": [
			        "IfcResourceLevelRelationship"
			      ],
			      "fields": {
			        "RelatingConstraint": {
			          "type": "IfcConstraint",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "RelatedResourceObjects": {
			          "type": "IfcResourceObjectSelect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcResourceLevelRelationship": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcResourceTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSchedulingTime"
			      ],
			      "fields": {
			        "ScheduleWork": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleUsage": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleUsageAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleStart": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleFinish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleContour": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LevelingDelay": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IsOverAllocated": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StatusTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualWork": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualUsage": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualUsageAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualStart": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualFinish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RemainingWork": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RemainingUsage": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RemainingUsageAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Completion": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompletionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRevolvedAreaSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSweptAreaSolid"
			      ],
			      "fields": {
			        "Axis": {
			          "type": "IfcAxis1Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Angle": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AngleAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRevolvedAreaSolidTapered": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcRevolvedAreaSolid"
			      ],
			      "fields": {
			        "EndSweptArea": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRightCircularCone": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCsgPrimitive3D"
			      ],
			      "fields": {
			        "Height": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRightCircularCylinder": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCsgPrimitive3D"
			      ],
			      "fields": {
			        "Height": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRoof": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRoofType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRoot": {
			      "domain": "ifckernel",
			      "superclasses": [],
			      "fields": {
			        "GlobalId": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OwnerHistory": {
			          "type": "IfcOwnerHistory",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRoundedRectangleProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcRectangleProfileDef"
			      ],
			      "fields": {
			        "RoundingRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RoundingRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSIUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcNamedUnit"
			      ],
			      "fields": {
			        "Prefix": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSanitaryTerminal": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSanitaryTerminalType": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSchedulingTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DataOrigin": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedDataOrigin": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSeamCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSurfaceCurve"
			      ],
			      "fields": {}
			    },
			    "IfcSectionProperties": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcPreDefinedProperties"
			      ],
			      "fields": {
			        "SectionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartProfile": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "EndProfile": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSectionReinforcementProperties": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcPreDefinedProperties"
			      ],
			      "fields": {
			        "LongitudinalStartPosition": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalStartPositionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalEndPosition": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongitudinalEndPositionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransversePosition": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransversePositionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReinforcementRole": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SectionDefinition": {
			          "type": "IfcSectionProperties",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionReinforcementDefinitions": {
			          "type": "IfcReinforcementBarProperties",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSectionedSpine": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "SpineCurve": {
			          "type": "IfcCompositeCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSections": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "CrossSectionPositions": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSensor": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSensorType": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcShadingDevice": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcShadingDeviceType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcShapeAspect": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [],
			      "fields": {
			        "ShapeRepresentations": {
			          "type": "IfcShapeModel",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ProductDefinitional": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PartOfProductDefinitionShape": {
			          "type": "IfcProductRepresentationSelect",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcShapeModel": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcRepresentation"
			      ],
			      "fields": {
			        "OfShapeAspect": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcShapeRepresentation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcShapeModel"
			      ],
			      "fields": {}
			    },
			    "IfcShellBasedSurfaceModel": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "SbsmBoundary": {
			          "type": "IfcShell",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSimpleProperty": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [
			        "IfcProperty"
			      ],
			      "fields": {}
			    },
			    "IfcSimplePropertyTemplate": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcPropertyTemplate"
			      ],
			      "fields": {
			        "TemplateType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PrimaryMeasureType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SecondaryMeasureType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Enumerators": {
			          "type": "IfcPropertyEnumeration",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PrimaryUnit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SecondaryUnit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Expression": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AccessState": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSite": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialStructureElement"
			      ],
			      "fields": {
			        "RefLatitude": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "RefLongitude": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "RefElevation": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RefElevationAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LandTitleNumber": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SiteAddress": {
			          "type": "IfcPostalAddress",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSlab": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSlabElementedCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcSlab"
			      ],
			      "fields": {}
			    },
			    "IfcSlabStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcSlab"
			      ],
			      "fields": {}
			    },
			    "IfcSlabType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSlippageConnectionCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralConnectionCondition"
			      ],
			      "fields": {
			        "SlippageX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SlippageXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SlippageY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SlippageYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SlippageZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SlippageZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSolarDevice": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSolarDeviceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSolidModel": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcBooleanOperand",
			        "IfcSolidOrShell"
			      ],
			      "fields": {
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpace": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialStructureElement",
			        "IfcSpaceBoundarySelect"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElevationWithFlooring": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElevationWithFlooringAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasCoverings": {
			          "type": "IfcRelCoversSpaces",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "BoundedBy": {
			          "type": "IfcRelSpaceBoundary",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcSpaceHeater": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpaceHeaterType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpaceType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialStructureElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpatialElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcProduct"
			      ],
			      "fields": {
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ContainsElements": {
			          "type": "IfcRelContainedInSpatialStructure",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ServicedBySystems": {
			          "type": "IfcRelServicesBuildings",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "ReferencesElements": {
			          "type": "IfcRelReferencedInSpatialStructure",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcSpatialElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcTypeProduct"
			      ],
			      "fields": {
			        "ElementType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpatialStructureElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialElement"
			      ],
			      "fields": {
			        "CompositionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpatialStructureElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialElementType"
			      ],
			      "fields": {}
			    },
			    "IfcSpatialZone": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpatialZoneType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSpatialElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSphere": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcCsgPrimitive3D"
			      ],
			      "fields": {
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSphericalSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcElementarySurface"
			      ],
			      "fields": {
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStackTerminal": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStackTerminalType": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStair": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStairFlight": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "NumberOfRisers": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NumberOfTreads": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RiserHeight": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RiserHeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TreadLength": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TreadLengthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStairFlightType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStairType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralAction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralActivity"
			      ],
			      "fields": {
			        "DestabilizingLoad": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralActivity": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcProduct"
			      ],
			      "fields": {
			        "AppliedLoad": {
			          "type": "IfcStructuralLoad",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "GlobalOrLocal": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AssignedToStructuralItem": {
			          "type": "IfcRelConnectsStructuralActivity",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcStructuralAnalysisModel": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcSystem"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OrientationOf2DPlane": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LoadedBy": {
			          "type": "IfcStructuralLoadGroup",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasResults": {
			          "type": "IfcStructuralResultGroup",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "SharedPlacement": {
			          "type": "IfcObjectPlacement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralConnection": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralItem"
			      ],
			      "fields": {
			        "AppliedCondition": {
			          "type": "IfcBoundaryCondition",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ConnectsStructuralMembers": {
			          "type": "IfcRelConnectsStructuralMember",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcStructuralConnectionCondition": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralCurveAction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralAction"
			      ],
			      "fields": {
			        "ProjectedOrTrue": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralCurveConnection": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralConnection"
			      ],
			      "fields": {
			        "Axis": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralCurveMember": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralMember"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Axis": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralCurveMemberVarying": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralCurveMember"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralCurveReaction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralReaction"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralItem": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcProduct",
			        "IfcStructuralActivityAssignmentSelect"
			      ],
			      "fields": {
			        "AssignedStructuralActivity": {
			          "type": "IfcRelConnectsStructuralActivity",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcStructuralLinearAction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralCurveAction"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralLoad": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadCase": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralLoadGroup"
			      ],
			      "fields": {
			        "SelfWeightCoefficients": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "SelfWeightCoefficientsAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadConfiguration": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoad"
			      ],
			      "fields": {
			        "Values": {
			          "type": "IfcStructuralLoadOrResult",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Locations": {
			          "type": "ListOfIfcLengthMeasure",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadGroup": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcGroup"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActionSource": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Coefficient": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CoefficientAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Purpose": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SourceOfResultGroup": {
			          "type": "IfcStructuralResultGroup",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "LoadGroupFor": {
			          "type": "IfcStructuralAnalysisModel",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcStructuralLoadLinearForce": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadStatic"
			      ],
			      "fields": {
			        "LinearForceX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearForceXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearForceY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearForceYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearForceZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearForceZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearMomentX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearMomentXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearMomentY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearMomentYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearMomentZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LinearMomentZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadOrResult": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoad"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralLoadPlanarForce": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadStatic"
			      ],
			      "fields": {
			        "PlanarForceX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PlanarForceXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PlanarForceY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PlanarForceYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PlanarForceZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PlanarForceZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadSingleDisplacement": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadStatic"
			      ],
			      "fields": {
			        "DisplacementX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DisplacementXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DisplacementY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DisplacementYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DisplacementZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DisplacementZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalDisplacementRX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalDisplacementRXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalDisplacementRY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalDisplacementRYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalDisplacementRZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RotationalDisplacementRZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadSingleDisplacementDistortion": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadSingleDisplacement"
			      ],
			      "fields": {
			        "Distortion": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DistortionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadSingleForce": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadStatic"
			      ],
			      "fields": {
			        "ForceX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ForceXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ForceY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ForceYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ForceZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ForceZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MomentX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MomentXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MomentY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MomentYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MomentZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MomentZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadSingleForceWarping": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadSingleForce"
			      ],
			      "fields": {
			        "WarpingMoment": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WarpingMomentAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralLoadStatic": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadOrResult"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralLoadTemperature": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadStatic"
			      ],
			      "fields": {
			        "DeltaTConstant": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DeltaTConstantAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DeltaTY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DeltaTYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DeltaTZ": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DeltaTZAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralMember": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralItem"
			      ],
			      "fields": {
			        "ConnectedBy": {
			          "type": "IfcRelConnectsStructuralMember",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcStructuralPlanarAction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralSurfaceAction"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralPointAction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralAction"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralPointConnection": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralConnection"
			      ],
			      "fields": {
			        "ConditionCoordinateSystem": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralPointReaction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralReaction"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralReaction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralActivity"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralResultGroup": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcGroup"
			      ],
			      "fields": {
			        "TheoryType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ResultForLoadGroup": {
			          "type": "IfcStructuralLoadGroup",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "IsLinear": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ResultGroupFor": {
			          "type": "IfcStructuralAnalysisModel",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcStructuralSurfaceAction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralAction"
			      ],
			      "fields": {
			        "ProjectedOrTrue": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralSurfaceConnection": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralConnection"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralSurfaceMember": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralMember"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Thickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStructuralSurfaceMemberVarying": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralSurfaceMember"
			      ],
			      "fields": {}
			    },
			    "IfcStructuralSurfaceReaction": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [
			        "IfcStructuralReaction"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStyleModel": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcRepresentation"
			      ],
			      "fields": {}
			    },
			    "IfcStyledItem": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcRepresentationItem"
			      ],
			      "fields": {
			        "Item": {
			          "type": "IfcRepresentationItem",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        },
			        "Styles": {
			          "type": "IfcStyleAssignmentSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStyledRepresentation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcStyleModel"
			      ],
			      "fields": {}
			    },
			    "IfcSubContractResource": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResource"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSubContractResourceType": {
			      "domain": "ifcconstructionmgmtdomain",
			      "superclasses": [
			        "IfcConstructionResourceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSubedge": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcEdge"
			      ],
			      "fields": {
			        "ParentEdge": {
			          "type": "IfcEdge",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcGeometricSetSelect",
			        "IfcSurfaceOrFaceSurface"
			      ],
			      "fields": {
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcCurve",
			        "IfcCurveOnSurface"
			      ],
			      "fields": {
			        "Curve3D": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "AssociatedGeometry": {
			          "type": "IfcPcurve",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "MasterRepresentation": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceCurveSweptAreaSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSweptAreaSolid"
			      ],
			      "fields": {
			        "Directrix": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "StartParam": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartParamAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndParam": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndParamAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferenceSurface": {
			          "type": "IfcSurface",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceFeature": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcFeatureElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceOfLinearExtrusion": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSweptSurface"
			      ],
			      "fields": {
			        "ExtrudedDirection": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceOfRevolution": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSweptSurface"
			      ],
			      "fields": {
			        "AxisPosition": {
			          "type": "IfcAxis1Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceReinforcementArea": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [
			        "IfcStructuralLoadOrResult"
			      ],
			      "fields": {
			        "SurfaceReinforcement1": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "SurfaceReinforcement1AsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "SurfaceReinforcement2": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "SurfaceReinforcement2AsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "ShearReinforcement": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ShearReinforcementAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationStyle",
			        "IfcPresentationStyleSelect"
			      ],
			      "fields": {
			        "Side": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Styles": {
			          "type": "IfcSurfaceStyleElementSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceStyleLighting": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcSurfaceStyleElementSelect"
			      ],
			      "fields": {
			        "DiffuseTransmissionColour": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "DiffuseReflectionColour": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TransmissionColour": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ReflectanceColour": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceStyleRefraction": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcSurfaceStyleElementSelect"
			      ],
			      "fields": {
			        "RefractionIndex": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RefractionIndexAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DispersionFactor": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DispersionFactorAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceStyleRendering": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcSurfaceStyleShading"
			      ],
			      "fields": {
			        "DiffuseColour": {
			          "type": "IfcColourOrFactor",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TransmissionColour": {
			          "type": "IfcColourOrFactor",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "DiffuseTransmissionColour": {
			          "type": "IfcColourOrFactor",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ReflectionColour": {
			          "type": "IfcColourOrFactor",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SpecularColour": {
			          "type": "IfcColourOrFactor",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "SpecularHighlight": {
			          "type": "IfcSpecularHighlightSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ReflectanceMethod": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceStyleShading": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcSurfaceStyleElementSelect"
			      ],
			      "fields": {
			        "SurfaceColour": {
			          "type": "IfcColourRgb",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Transparency": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransparencyAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSurfaceStyleWithTextures": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem",
			        "IfcSurfaceStyleElementSelect"
			      ],
			      "fields": {
			        "Textures": {
			          "type": "IfcSurfaceTexture",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcSurfaceTexture": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "RepeatS": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RepeatT": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Mode": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TextureTransform": {
			          "type": "IfcCartesianTransformationOperator2D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Parameter": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "IsMappedBy": {
			          "type": "IfcTextureCoordinate",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "UsedInStyles": {
			          "type": "IfcSurfaceStyleWithTextures",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcSweptAreaSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSolidModel"
			      ],
			      "fields": {
			        "SweptArea": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Position": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSweptDiskSolid": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSolidModel"
			      ],
			      "fields": {
			        "Directrix": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Radius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InnerRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "InnerRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartParam": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartParamAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndParam": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndParamAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSweptDiskSolidPolygonal": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcSweptDiskSolid"
			      ],
			      "fields": {
			        "FilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSweptSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcSurface"
			      ],
			      "fields": {
			        "SweptCurve": {
			          "type": "IfcProfileDef",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Position": {
			          "type": "IfcAxis2Placement3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSwitchingDevice": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSwitchingDeviceType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSystem": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcGroup"
			      ],
			      "fields": {
			        "ServicesBuildings": {
			          "type": "IfcRelServicesBuildings",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcSystemFurnitureElement": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcFurnishingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSystemFurnitureElementType": {
			      "domain": "ifcsharedfacilitieselements",
			      "superclasses": [
			        "IfcFurnishingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeEdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeEdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebEdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebEdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTable": {
			      "domain": "ifcutilityresource",
			      "superclasses": [
			        "IfcMetricValueSelect",
			        "IfcObjectReferenceSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Rows": {
			          "type": "IfcTableRow",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Columns": {
			          "type": "IfcTableColumn",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "NumberOfCellsInRow": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NumberOfDataRows": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NumberOfHeadings": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTableColumn": {
			      "domain": "ifcutilityresource",
			      "superclasses": [],
			      "fields": {
			        "Identifier": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Unit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ReferencePath": {
			          "type": "IfcReference",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTableRow": {
			      "domain": "ifcutilityresource",
			      "superclasses": [],
			      "fields": {
			        "RowCells": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "IsHeading": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTank": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowStorageDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTankType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowStorageDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTask": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcProcess"
			      ],
			      "fields": {
			        "Status": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WorkMethod": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IsMilestone": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Priority": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TaskTime": {
			          "type": "IfcTaskTime",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTaskTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSchedulingTime"
			      ],
			      "fields": {
			        "DurationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleDuration": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleStart": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ScheduleFinish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EarlyStart": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EarlyFinish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LateStart": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LateFinish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FreeFloat": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TotalFloat": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "IsCritical": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StatusTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualDuration": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualStart": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ActualFinish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "RemainingTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Completion": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CompletionAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTaskTimeRecurring": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcTaskTime"
			      ],
			      "fields": {
			        "Recurrence": {
			          "type": "IfcRecurrencePattern",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTaskType": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcTypeProcess"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WorkMethod": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTelecomAddress": {
			      "domain": "ifcactorresource",
			      "superclasses": [
			        "IfcAddress"
			      ],
			      "fields": {
			        "TelephoneNumbers": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "FacsimileNumbers": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "PagerNumber": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ElectronicMailAddresses": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "WWWHomePageURL": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MessagingIDs": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTendon": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionForce": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TensionForceAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PreStress": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PreStressAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrictionCoefficient": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrictionCoefficientAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AnchorageSlip": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "AnchorageSlipAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MinCurvatureRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MinCurvatureRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTendonAnchor": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTendonAnchorType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTendonType": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcReinforcingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "NominalDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionArea": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CrossSectionAreaAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SheathDiameter": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SheathDiameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTessellatedFaceSet": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcTessellatedItem",
			        "IfcBooleanOperand"
			      ],
			      "fields": {
			        "Coordinates": {
			          "type": "IfcCartesianPointList3D",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "HasColours": {
			          "type": "IfcIndexedColourMap",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "HasTextures": {
			          "type": "IfcIndexedTextureMap",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTessellatedItem": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {}
			    },
			    "IfcTextLiteral": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem"
			      ],
			      "fields": {
			        "Literal": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Placement": {
			          "type": "IfcAxis2Placement",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Path": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextLiteralWithExtent": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [
			        "IfcTextLiteral"
			      ],
			      "fields": {
			        "Extent": {
			          "type": "IfcPlanarExtent",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "BoxAlignment": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationStyle",
			        "IfcPresentationStyleSelect"
			      ],
			      "fields": {
			        "TextCharacterAppearance": {
			          "type": "IfcTextStyleForDefinedFont",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TextStyle": {
			          "type": "IfcTextStyleTextModel",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TextFontStyle": {
			          "type": "IfcTextFontSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "ModelOrDraughting": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextStyleFontModel": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPreDefinedTextFont"
			      ],
			      "fields": {
			        "FontFamily": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "FontStyle": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FontVariant": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FontWeight": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FontSize": {
			          "type": "IfcSizeSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextStyleForDefinedFont": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "Colour": {
			          "type": "IfcColour",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "BackgroundColour": {
			          "type": "IfcColour",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextStyleTextModel": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "TextIndent": {
			          "type": "IfcSizeSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TextAlign": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TextDecoration": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LetterSpacing": {
			          "type": "IfcSizeSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "WordSpacing": {
			          "type": "IfcSizeSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "TextTransform": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LineHeight": {
			          "type": "IfcSizeSelect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextureCoordinate": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "Maps": {
			          "type": "IfcSurfaceTexture",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcTextureCoordinateGenerator": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcTextureCoordinate"
			      ],
			      "fields": {
			        "Mode": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Parameter": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "ParameterAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextureMap": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcTextureCoordinate"
			      ],
			      "fields": {
			        "Vertices": {
			          "type": "IfcTextureVertex",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "MappedTo": {
			          "type": "IfcFace",
			          "reference": true,
			          "many": false,
			          "inverse": true
			        }
			      }
			    },
			    "IfcTextureVertex": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "Coordinates": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "CoordinatesAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextureVertexList": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationItem"
			      ],
			      "fields": {
			        "TexCoordsList": {
			          "type": "ListOfIfcParameterValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTimePeriod": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "StartTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTimeSeries": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcMetricValueSelect",
			        "IfcObjectReferenceSelect",
			        "IfcResourceObjectSelect"
			      ],
			      "fields": {
			        "Name": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Description": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EndTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TimeSeriesDataType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DataOrigin": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedDataOrigin": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Unit": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "HasExternalReference": {
			          "type": "IfcExternalReferenceRelationship",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcTimeSeriesValue": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "ListValues": {
			          "type": "IfcValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTopologicalRepresentationItem": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcRepresentationItem"
			      ],
			      "fields": {}
			    },
			    "IfcTopologyRepresentation": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [
			        "IfcShapeModel"
			      ],
			      "fields": {}
			    },
			    "IfcToroidalSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcElementarySurface"
			      ],
			      "fields": {
			        "MajorRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MajorRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MinorRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MinorRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTransformer": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTransformerType": {
			      "domain": "ifcelectricaldomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTransportElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTransportElementType": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTrapeziumProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "BottomXDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "BottomXDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopXDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopXDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YDim": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "YDimAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopXOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TopXOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTriangulatedFaceSet": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [
			        "IfcTessellatedFaceSet"
			      ],
			      "fields": {
			        "Normals": {
			          "type": "ListOfIfcParameterValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Closed": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "CoordIndex": {
			          "type": "ListOfELong",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "PnIndex": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "NumberOfTriangles": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTrimmedCurve": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcBoundedCurve"
			      ],
			      "fields": {
			        "BasisCurve": {
			          "type": "IfcCurve",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Trim1": {
			          "type": "IfcTrimmingSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Trim2": {
			          "type": "IfcTrimmingSelect",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "SenseAgreement": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MasterRepresentation": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTubeBundle": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTubeBundleType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTypeObject": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcObjectDefinition"
			      ],
			      "fields": {
			        "ApplicableOccurrence": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "HasPropertySets": {
			          "type": "IfcPropertySetDefinition",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "Types": {
			          "type": "IfcRelDefinesByType",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcTypeProcess": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcTypeObject",
			        "IfcProcessSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ProcessType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OperatesOn": {
			          "type": "IfcRelAssignsToProcess",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcTypeProduct": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcTypeObject",
			        "IfcProductSelect"
			      ],
			      "fields": {
			        "RepresentationMaps": {
			          "type": "IfcRepresentationMap",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Tag": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ReferencedBy": {
			          "type": "IfcRelAssignsToProduct",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcTypeResource": {
			      "domain": "ifckernel",
			      "superclasses": [
			        "IfcTypeObject",
			        "IfcResourceSelect"
			      ],
			      "fields": {
			        "Identification": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LongDescription": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ResourceType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ResourceOf": {
			          "type": "IfcRelAssignsToResource",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        }
			      }
			    },
			    "IfcUShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeSlope": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeSlopeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcUnitAssignment": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [],
			      "fields": {
			        "Units": {
			          "type": "IfcUnit",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcUnitaryControlElement": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcUnitaryControlElementType": {
			      "domain": "ifcbuildingcontrolsdomain",
			      "superclasses": [
			        "IfcDistributionControlElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcUnitaryEquipment": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDevice"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcUnitaryEquipmentType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcEnergyConversionDeviceType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcValve": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowController"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcValveType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcFlowControllerType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVector": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [
			        "IfcGeometricRepresentationItem",
			        "IfcHatchLineDistanceSelect",
			        "IfcVectorOrDirection"
			      ],
			      "fields": {
			        "Orientation": {
			          "type": "IfcDirection",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Magnitude": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MagnitudeAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Dim": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVertex": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcTopologicalRepresentationItem"
			      ],
			      "fields": {}
			    },
			    "IfcVertexLoop": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcLoop"
			      ],
			      "fields": {
			        "LoopVertex": {
			          "type": "IfcVertex",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVertexPoint": {
			      "domain": "ifctopologyresource",
			      "superclasses": [
			        "IfcVertex",
			        "IfcPointOrVertexPoint"
			      ],
			      "fields": {
			        "VertexGeometry": {
			          "type": "IfcPoint",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVibrationIsolator": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcElementComponent"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVibrationIsolatorType": {
			      "domain": "ifchvacdomain",
			      "superclasses": [
			        "IfcElementComponentType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVirtualElement": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcElement"
			      ],
			      "fields": {}
			    },
			    "IfcVirtualGridIntersection": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [
			        "IfcGridPlacementDirectionSelect"
			      ],
			      "fields": {
			        "IntersectingAxes": {
			          "type": "IfcGridAxis",
			          "reference": true,
			          "many": true,
			          "inverse": true
			        },
			        "OffsetDistances": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "OffsetDistancesAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVoidingFeature": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [
			        "IfcFeatureElementSubtraction"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWall": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWallElementedCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcWall"
			      ],
			      "fields": {}
			    },
			    "IfcWallStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcWall"
			      ],
			      "fields": {}
			    },
			    "IfcWallType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWasteTerminal": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminal"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWasteTerminalType": {
			      "domain": "ifcplumbingfireprotectiondomain",
			      "superclasses": [
			        "IfcFlowTerminalType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWindow": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElement"
			      ],
			      "fields": {
			        "OverallHeight": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallHeightAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OverallWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PartitioningType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedPartitioningType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWindowLiningProperties": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcPreDefinedPropertySet"
			      ],
			      "fields": {
			        "LiningDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransomThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TransomThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MullionThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "MullionThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FirstTransomOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FirstTransomOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SecondTransomOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SecondTransomOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FirstMullionOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FirstMullionOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SecondMullionOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "SecondMullionOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ShapeAspectStyle": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "LiningOffset": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningOffsetAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetX": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetXAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetY": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "LiningToPanelOffsetYAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWindowPanelProperties": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcPreDefinedPropertySet"
			      ],
			      "fields": {
			        "OperationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PanelPosition": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameDepth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameDepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FrameThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ShapeAspectStyle": {
			          "type": "IfcShapeAspect",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWindowStandardCase": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcWindow"
			      ],
			      "fields": {}
			    },
			    "IfcWindowStyle": {
			      "domain": "ifcarchitecturedomain",
			      "superclasses": [
			        "IfcTypeProduct"
			      ],
			      "fields": {
			        "ConstructionType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "OperationType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ParameterTakesPrecedence": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Sizeable": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWindowType": {
			      "domain": "ifcsharedbldgelements",
			      "superclasses": [
			        "IfcBuildingElementType"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "PartitioningType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "ParameterTakesPrecedence": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "UserDefinedPartitioningType": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWorkCalendar": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "WorkingTimes": {
			          "type": "IfcWorkTime",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "ExceptionTimes": {
			          "type": "IfcWorkTime",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWorkControl": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcControl"
			      ],
			      "fields": {
			        "CreationDate": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Creators": {
			          "type": "IfcPerson",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        },
			        "Purpose": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Duration": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "TotalFloat": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "StartTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FinishTime": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWorkPlan": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcWorkControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWorkSchedule": {
			      "domain": "ifcprocessextension",
			      "superclasses": [
			        "IfcWorkControl"
			      ],
			      "fields": {
			        "PredefinedType": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWorkTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSchedulingTime"
			      ],
			      "fields": {
			        "RecurrencePattern": {
			          "type": "IfcRecurrencePattern",
			          "reference": true,
			          "many": false,
			          "inverse": false
			        },
			        "Start": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "Finish": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcZShapeProfileDef": {
			      "domain": "ifcprofileresource",
			      "superclasses": [
			        "IfcParameterizedProfileDef"
			      ],
			      "fields": {
			        "Depth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "DepthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeWidth": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeWidthAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "WebThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThickness": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FlangeThicknessAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "FilletRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeRadius": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "EdgeRadiusAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcZone": {
			      "domain": "ifcproductextension",
			      "superclasses": [
			        "IfcSystem"
			      ],
			      "fields": {
			        "LongName": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcStrippedOptional": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAbsorbedDoseMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAccelerationMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAmountOfSubstanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAngularVelocityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAreaDensityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcAreaMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBinary": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "bytearray",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoolean": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcModulusOfRotationalSubgradeReactionSelect",
			        "IfcModulusOfSubgradeReactionSelect",
			        "IfcModulusOfTranslationalSubgradeReactionSelect",
			        "IfcRotationalStiffnessSelect",
			        "IfcSimpleValue",
			        "IfcTranslationalStiffnessSelect",
			        "IfcWarpingStiffnessSelect",
			        "IfcValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCardinalPointReference": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcContextDependentMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCountMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcCurvatureMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDate": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDateTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDayInMonthNumber": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDayInWeekNumber": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDescriptiveMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue",
			        "IfcSizeSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDimensionCount": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDoseEquivalentMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDuration": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSimpleValue",
			        "IfcTimeOrRatioSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcDynamicViscosityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricCapacitanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricChargeMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricConductanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricCurrentMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricResistanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcElectricVoltageMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcEnergyMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFontStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFontVariant": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFontWeight": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcForceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcFrequencyMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcGloballyUniqueId": {
			      "domain": "ifcutilityresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcHeatFluxDensityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcHeatingValueMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIdentifier": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIlluminanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcInductanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcInteger": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIntegerCountRateMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIonConcentrationMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcIsothermalMoistureCapacityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcKinematicViscosityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLabel": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLengthMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcBendingParameterSelect",
			        "IfcMeasureValue",
			        "IfcSizeSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLinearForceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLinearMomentMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLinearStiffnessMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue",
			        "IfcTranslationalStiffnessSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLinearVelocityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLogical": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLuminousFluxMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLuminousIntensityDistributionMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLuminousIntensityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMagneticFluxDensityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMagneticFluxMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMassDensityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMassFlowRateMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMassMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMassPerLengthMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcModulusOfElasticityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcModulusOfLinearSubgradeReactionMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue",
			        "IfcModulusOfTranslationalSubgradeReactionSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcModulusOfRotationalSubgradeReactionMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue",
			        "IfcModulusOfRotationalSubgradeReactionSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcModulusOfSubgradeReactionMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue",
			        "IfcModulusOfSubgradeReactionSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMoistureDiffusivityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMolecularWeightMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMomentOfInertiaMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMonetaryMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcMonthInYearNumber": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcNumericMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPHMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcParameterValue": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue",
			        "IfcTrimmingSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlanarForceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPlaneAngleMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcBendingParameterSelect",
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPowerMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPresentableText": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcPressureMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRadioActivityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRatioMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue",
			        "IfcSizeSelect",
			        "IfcTimeOrRatioSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcReal": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRotationalFrequencyMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRotationalMassMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcRotationalStiffnessMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue",
			        "IfcRotationalStiffnessSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSectionModulusMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSectionalAreaIntegralMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcShearModulusMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSolidAngleMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSoundPowerLevelMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSoundPowerMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSoundPressureLevelMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSoundPressureMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpecificHeatCapacityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpecularExponent": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcSpecularHighlightSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcSpecularRoughness": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcSpecularHighlightSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTemperatureGradientMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTemperatureRateOfChangeMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcText": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextAlignment": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextDecoration": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextFontName": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTextTransformation": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcThermalAdmittanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcThermalConductivityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcThermalExpansionCoefficientMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcThermalResistanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcThermalTransmittanceMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcThermodynamicTemperatureMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTime": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTimeMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTimeStamp": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [
			        "IfcSimpleValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcTorqueMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcURIReference": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {
			        "wrappedValue": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVaporPermeabilityMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVolumeMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcVolumetricFlowRateMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWarpingConstantMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcWarpingMomentMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue",
			        "IfcWarpingStiffnessSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcBoxAlignment": {
			      "domain": "ifcpresentationdefinitionresource",
			      "superclasses": [
			        "IfcLabel"
			      ],
			      "fields": {}
			    },
			    "IfcCompoundPlaneAngleMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcDerivedMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "long",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcLanguageId": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [
			        "IfcIdentifier"
			      ],
			      "fields": {}
			    },
			    "IfcNonNegativeLengthMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcLengthMeasure",
			        "IfcMeasureValue"
			      ],
			      "fields": {}
			    },
			    "IfcNormalisedRatioMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcRatioMeasure",
			        "IfcColourOrFactor",
			        "IfcMeasureValue",
			        "IfcSizeSelect"
			      ],
			      "fields": {}
			    },
			    "IfcPositiveInteger": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcInteger"
			      ],
			      "fields": {}
			    },
			    "IfcPositiveLengthMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcLengthMeasure",
			        "IfcHatchLineDistanceSelect",
			        "IfcMeasureValue",
			        "IfcSizeSelect"
			      ],
			      "fields": {}
			    },
			    "IfcPositivePlaneAngleMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcPlaneAngleMeasure",
			        "IfcMeasureValue"
			      ],
			      "fields": {}
			    },
			    "IfcPositiveRatioMeasure": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcRatioMeasure",
			        "IfcMeasureValue",
			        "IfcSizeSelect"
			      ],
			      "fields": {}
			    },
			    "IfcActionRequestTypeEnum": {},
			    "IfcActionSourceTypeEnum": {},
			    "IfcActionTypeEnum": {},
			    "IfcActuatorTypeEnum": {},
			    "IfcAddressTypeEnum": {},
			    "IfcAirTerminalBoxTypeEnum": {},
			    "IfcAirTerminalTypeEnum": {},
			    "IfcAirToAirHeatRecoveryTypeEnum": {},
			    "IfcAlarmTypeEnum": {},
			    "IfcAnalysisModelTypeEnum": {},
			    "IfcAnalysisTheoryTypeEnum": {},
			    "IfcArithmeticOperatorEnum": {},
			    "IfcAssemblyPlaceEnum": {},
			    "IfcAudioVisualApplianceTypeEnum": {},
			    "IfcBSplineCurveForm": {},
			    "IfcBSplineSurfaceForm": {},
			    "IfcBeamTypeEnum": {},
			    "IfcBenchmarkEnum": {},
			    "IfcBoilerTypeEnum": {},
			    "IfcBooleanOperator": {},
			    "IfcBuildingElementPartTypeEnum": {},
			    "IfcBuildingElementProxyTypeEnum": {},
			    "IfcBuildingSystemTypeEnum": {},
			    "IfcBurnerTypeEnum": {},
			    "IfcCableCarrierFittingTypeEnum": {},
			    "IfcCableCarrierSegmentTypeEnum": {},
			    "IfcCableFittingTypeEnum": {},
			    "IfcCableSegmentTypeEnum": {},
			    "IfcChangeActionEnum": {},
			    "IfcChillerTypeEnum": {},
			    "IfcChimneyTypeEnum": {},
			    "IfcCoilTypeEnum": {},
			    "IfcColumnTypeEnum": {},
			    "IfcCommunicationsApplianceTypeEnum": {},
			    "IfcComplexPropertyTemplateTypeEnum": {},
			    "IfcCompressorTypeEnum": {},
			    "IfcCondenserTypeEnum": {},
			    "IfcConnectionTypeEnum": {},
			    "IfcConstraintEnum": {},
			    "IfcConstructionEquipmentResourceTypeEnum": {},
			    "IfcConstructionMaterialResourceTypeEnum": {},
			    "IfcConstructionProductResourceTypeEnum": {},
			    "IfcControllerTypeEnum": {},
			    "IfcCooledBeamTypeEnum": {},
			    "IfcCoolingTowerTypeEnum": {},
			    "IfcCostItemTypeEnum": {},
			    "IfcCostScheduleTypeEnum": {},
			    "IfcCoveringTypeEnum": {},
			    "IfcCrewResourceTypeEnum": {},
			    "IfcCurtainWallTypeEnum": {},
			    "IfcCurveInterpolationEnum": {},
			    "IfcDamperTypeEnum": {},
			    "IfcDataOriginEnum": {},
			    "IfcDerivedUnitEnum": {},
			    "IfcDirectionSenseEnum": {},
			    "IfcDiscreteAccessoryTypeEnum": {},
			    "IfcDistributionChamberElementTypeEnum": {},
			    "IfcDistributionPortTypeEnum": {},
			    "IfcDistributionSystemEnum": {},
			    "IfcDocumentConfidentialityEnum": {},
			    "IfcDocumentStatusEnum": {},
			    "IfcDoorPanelOperationEnum": {},
			    "IfcDoorPanelPositionEnum": {},
			    "IfcDoorStyleConstructionEnum": {},
			    "IfcDoorStyleOperationEnum": {},
			    "IfcDoorTypeEnum": {},
			    "IfcDoorTypeOperationEnum": {},
			    "IfcDuctFittingTypeEnum": {},
			    "IfcDuctSegmentTypeEnum": {},
			    "IfcDuctSilencerTypeEnum": {},
			    "IfcElectricApplianceTypeEnum": {},
			    "IfcElectricDistributionBoardTypeEnum": {},
			    "IfcElectricFlowStorageDeviceTypeEnum": {},
			    "IfcElectricGeneratorTypeEnum": {},
			    "IfcElectricMotorTypeEnum": {},
			    "IfcElectricTimeControlTypeEnum": {},
			    "IfcElementAssemblyTypeEnum": {},
			    "IfcElementCompositionEnum": {},
			    "IfcEngineTypeEnum": {},
			    "IfcEvaporativeCoolerTypeEnum": {},
			    "IfcEvaporatorTypeEnum": {},
			    "IfcEventTriggerTypeEnum": {},
			    "IfcEventTypeEnum": {},
			    "IfcExternalSpatialElementTypeEnum": {},
			    "IfcFanTypeEnum": {},
			    "IfcFastenerTypeEnum": {},
			    "IfcFilterTypeEnum": {},
			    "IfcFireSuppressionTerminalTypeEnum": {},
			    "IfcFlowDirectionEnum": {},
			    "IfcFlowInstrumentTypeEnum": {},
			    "IfcFlowMeterTypeEnum": {},
			    "IfcFootingTypeEnum": {},
			    "IfcFurnitureTypeEnum": {},
			    "IfcGeographicElementTypeEnum": {},
			    "IfcGeometricProjectionEnum": {},
			    "IfcGlobalOrLocalEnum": {},
			    "IfcGridTypeEnum": {},
			    "IfcHeatExchangerTypeEnum": {},
			    "IfcHumidifierTypeEnum": {},
			    "IfcInterceptorTypeEnum": {},
			    "IfcInternalOrExternalEnum": {},
			    "IfcInventoryTypeEnum": {},
			    "IfcJunctionBoxTypeEnum": {},
			    "IfcKnotType": {},
			    "IfcLaborResourceTypeEnum": {},
			    "IfcLampTypeEnum": {},
			    "IfcLayerSetDirectionEnum": {},
			    "IfcLightDistributionCurveEnum": {},
			    "IfcLightEmissionSourceEnum": {},
			    "IfcLightFixtureTypeEnum": {},
			    "IfcLoadGroupTypeEnum": {},
			    "IfcLogicalOperatorEnum": {},
			    "IfcMechanicalFastenerTypeEnum": {},
			    "IfcMedicalDeviceTypeEnum": {},
			    "IfcMemberTypeEnum": {},
			    "IfcMotorConnectionTypeEnum": {},
			    "IfcNullStyleEnum": {},
			    "IfcObjectTypeEnum": {},
			    "IfcObjectiveEnum": {},
			    "IfcOccupantTypeEnum": {},
			    "IfcOpeningElementTypeEnum": {},
			    "IfcOutletTypeEnum": {},
			    "IfcPerformanceHistoryTypeEnum": {},
			    "IfcPermeableCoveringOperationEnum": {},
			    "IfcPermitTypeEnum": {},
			    "IfcPhysicalOrVirtualEnum": {},
			    "IfcPileConstructionEnum": {},
			    "IfcPileTypeEnum": {},
			    "IfcPipeFittingTypeEnum": {},
			    "IfcPipeSegmentTypeEnum": {},
			    "IfcPlateTypeEnum": {},
			    "IfcPreferredSurfaceCurveRepresentation": {},
			    "IfcProcedureTypeEnum": {},
			    "IfcProfileTypeEnum": {},
			    "IfcProjectOrderTypeEnum": {},
			    "IfcProjectedOrTrueLengthEnum": {},
			    "IfcProjectionElementTypeEnum": {},
			    "IfcPropertySetTemplateTypeEnum": {},
			    "IfcProtectiveDeviceTrippingUnitTypeEnum": {},
			    "IfcProtectiveDeviceTypeEnum": {},
			    "IfcPumpTypeEnum": {},
			    "IfcRailingTypeEnum": {},
			    "IfcRampFlightTypeEnum": {},
			    "IfcRampTypeEnum": {},
			    "IfcRecurrenceTypeEnum": {},
			    "IfcReflectanceMethodEnum": {},
			    "IfcReinforcingBarRoleEnum": {},
			    "IfcReinforcingBarSurfaceEnum": {},
			    "IfcReinforcingBarTypeEnum": {},
			    "IfcReinforcingMeshTypeEnum": {},
			    "IfcRoleEnum": {},
			    "IfcRoofTypeEnum": {},
			    "IfcSIPrefix": {},
			    "IfcSIUnitName": {},
			    "IfcSanitaryTerminalTypeEnum": {},
			    "IfcSectionTypeEnum": {},
			    "IfcSensorTypeEnum": {},
			    "IfcSequenceEnum": {},
			    "IfcShadingDeviceTypeEnum": {},
			    "IfcSimplePropertyTemplateTypeEnum": {},
			    "IfcSlabTypeEnum": {},
			    "IfcSolarDeviceTypeEnum": {},
			    "IfcSpaceHeaterTypeEnum": {},
			    "IfcSpaceTypeEnum": {},
			    "IfcSpatialZoneTypeEnum": {},
			    "IfcStackTerminalTypeEnum": {},
			    "IfcStairFlightTypeEnum": {},
			    "IfcStairTypeEnum": {},
			    "IfcStateEnum": {},
			    "IfcStructuralCurveActivityTypeEnum": {},
			    "IfcStructuralCurveMemberTypeEnum": {},
			    "IfcStructuralSurfaceActivityTypeEnum": {},
			    "IfcStructuralSurfaceMemberTypeEnum": {},
			    "IfcSubContractResourceTypeEnum": {},
			    "IfcSurfaceFeatureTypeEnum": {},
			    "IfcSurfaceSide": {},
			    "IfcSwitchingDeviceTypeEnum": {},
			    "IfcSystemFurnitureElementTypeEnum": {},
			    "IfcTankTypeEnum": {},
			    "IfcTaskDurationEnum": {},
			    "IfcTaskTypeEnum": {},
			    "IfcTendonAnchorTypeEnum": {},
			    "IfcTendonTypeEnum": {},
			    "IfcTextPath": {},
			    "IfcTimeSeriesDataTypeEnum": {},
			    "IfcTransformerTypeEnum": {},
			    "IfcTransitionCode": {},
			    "IfcTransportElementTypeEnum": {},
			    "IfcTrimmingPreference": {},
			    "IfcTubeBundleTypeEnum": {},
			    "IfcUnitEnum": {},
			    "IfcUnitaryControlElementTypeEnum": {},
			    "IfcUnitaryEquipmentTypeEnum": {},
			    "IfcValveTypeEnum": {},
			    "IfcVibrationIsolatorTypeEnum": {},
			    "IfcVoidingFeatureTypeEnum": {},
			    "IfcWallTypeEnum": {},
			    "IfcWasteTerminalTypeEnum": {},
			    "IfcWindowPanelOperationEnum": {},
			    "IfcWindowPanelPositionEnum": {},
			    "IfcWindowStyleConstructionEnum": {},
			    "IfcWindowStyleOperationEnum": {},
			    "IfcWindowTypeEnum": {},
			    "IfcWindowTypePartitioningEnum": {},
			    "IfcWorkCalendarTypeEnum": {},
			    "IfcWorkPlanTypeEnum": {},
			    "IfcWorkScheduleTypeEnum": {},
			    "IfcComplexNumber": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcMeasureValue"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        },
			        "wrappedValueAsString": {
			          "type": "string",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "IfcNullStyle": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcPresentationStyleSelect"
			      ],
			      "fields": {
			        "wrappedValue": {
			          "type": "enum",
			          "reference": false,
			          "many": false,
			          "inverse": false
			        }
			      }
			    },
			    "IfcActorSelect": {
			      "domain": "ifcactorresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcAppliedValueSelect": {
			      "domain": "ifccostresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcAxis2Placement": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcBendingParameterSelect": {
			      "domain": "ifcstructuralelementsdomain",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcBooleanOperand": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcClassificationReferenceSelect": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcClassificationSelect": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcColour": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcFillStyleSelect"
			      ],
			      "fields": {}
			    },
			    "IfcColourOrFactor": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcCoordinateReferenceSystemSelect": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcCsgSelect": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcCurveFontOrScaledCurveFontSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcCurveOnSurface": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcCurveOrEdgeCurve": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcCurveStyleFontSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [
			        "IfcCurveFontOrScaledCurveFontSelect"
			      ],
			      "fields": {}
			    },
			    "IfcDefinitionSelect": {
			      "domain": "ifckernel",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcDerivedMeasureValue": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcValue"
			      ],
			      "fields": {}
			    },
			    "IfcDocumentSelect": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcFillStyleSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcGeometricSetSelect": {
			      "domain": "ifcgeometricmodelresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcGridPlacementDirectionSelect": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcHatchLineDistanceSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcLayeredItem": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcLibrarySelect": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcLightDistributionDataSourceSelect": {
			      "domain": "ifcpresentationorganizationresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcMaterialSelect": {
			      "domain": "ifcmaterialresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcMeasureValue": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcValue"
			      ],
			      "fields": {}
			    },
			    "IfcMetricValueSelect": {
			      "domain": "ifcconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcModulusOfRotationalSubgradeReactionSelect": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcModulusOfSubgradeReactionSelect": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcModulusOfTranslationalSubgradeReactionSelect": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcObjectReferenceSelect": {
			      "domain": "ifcpropertyresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcPointOrVertexPoint": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcPresentationStyleSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcProcessSelect": {
			      "domain": "ifckernel",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcProductRepresentationSelect": {
			      "domain": "ifcrepresentationresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcProductSelect": {
			      "domain": "ifckernel",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcPropertySetDefinitionSelect": {
			      "domain": "ifckernel",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcResourceObjectSelect": {
			      "domain": "ifcexternalreferenceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcResourceSelect": {
			      "domain": "ifckernel",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcRotationalStiffnessSelect": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSegmentIndexSelect": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcShell": {
			      "domain": "ifctopologyresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSimpleValue": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcValue"
			      ],
			      "fields": {}
			    },
			    "IfcSizeSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSolidOrShell": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSpaceBoundarySelect": {
			      "domain": "ifcproductextension",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSpecularHighlightSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcStructuralActivityAssignmentSelect": {
			      "domain": "ifcstructuralanalysisdomain",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcStyleAssignmentSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSurfaceOrFaceSurface": {
			      "domain": "ifcgeometricconstraintresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcSurfaceStyleElementSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcTextFontSelect": {
			      "domain": "ifcpresentationappearanceresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcTimeOrRatioSelect": {
			      "domain": "ifcdatetimeresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcTranslationalStiffnessSelect": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcTrimmingSelect": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcUnit": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcValue": {
			      "domain": "ifcmeasureresource",
			      "superclasses": [
			        "IfcAppliedValueSelect",
			        "IfcMetricValueSelect"
			      ],
			      "fields": {}
			    },
			    "IfcVectorOrDirection": {
			      "domain": "ifcgeometryresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "IfcWarpingStiffnessSelect": {
			      "domain": "ifcstructuralloadresource",
			      "superclasses": [],
			      "fields": {}
			    },
			    "ListOfIfcCartesianPoint": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "List": {
			          "type": "IfcCartesianPoint",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "ListOfIfcLengthMeasure": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "List": {
			          "type": "IfcLengthMeasure",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "ListOfIfcNormalisedRatioMeasure": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "List": {
			          "type": "IfcNormalisedRatioMeasure",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "ListOfELong": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "List": {
			          "type": "long",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "ListOfEDouble": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "List": {
			          "type": "double",
			          "reference": false,
			          "many": true,
			          "inverse": false
			        }
			      }
			    },
			    "ListOfIfcParameterValue": {
			      "domain": null,
			      "superclasses": [],
			      "fields": {
			        "List": {
			          "type": "IfcParameterValue",
			          "reference": true,
			          "many": true,
			          "inverse": false
			        }
			      }
			    }
			  }
			};