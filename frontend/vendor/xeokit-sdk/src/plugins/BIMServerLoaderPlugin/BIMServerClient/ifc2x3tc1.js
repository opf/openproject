/**
 * @private
 */
export const ifc2x3tc1 = {
	"classes": {
		"Tristate": {},
		"Ifc2DCompositeCurve": {
			"domain": "ifcgeometryresource",
			"superclasses": [
				"IfcCompositeCurve"
			],
			"fields": {}
		},
		"IfcActionRequest": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"RequestID": {
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
			"superclasses": [],
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
		"IfcAngularDimension": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDimensionCurveDirectedCallout"
			],
			"fields": {}
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
		"IfcAnnotationCurveOccurrence": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcAnnotationOccurrence",
				"IfcDraughtingCalloutElement"
			],
			"fields": {}
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
		"IfcAnnotationFillAreaOccurrence": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcAnnotationOccurrence"
			],
			"fields": {
				"FillStyleTarget": {
					"type": "IfcPoint",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"GlobalOrLocal": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcAnnotationOccurrence": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcStyledItem"
			],
			"fields": {}
		},
		"IfcAnnotationSurface": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcGeometricRepresentationItem"
			],
			"fields": {
				"Item": {
					"type": "IfcGeometricRepresentationItem",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"TextureCoordinates": {
					"type": "IfcTextureCoordinate",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcAnnotationSurfaceOccurrence": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcAnnotationOccurrence"
			],
			"fields": {}
		},
		"IfcAnnotationSymbolOccurrence": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcAnnotationOccurrence",
				"IfcDraughtingCalloutElement"
			],
			"fields": {}
		},
		"IfcAnnotationTextOccurrence": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcAnnotationOccurrence",
				"IfcDraughtingCalloutElement"
			],
			"fields": {}
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
				"IfcObjectReferenceSelect"
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
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"FixedUntilDate": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ValuesReferenced": {
					"type": "IfcReferencesValueDocument",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"ValueOfComponents": {
					"type": "IfcAppliedValueRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"IsComponentIn": {
					"type": "IfcAppliedValueRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcAppliedValueRelationship": {
			"domain": "ifccostresource",
			"superclasses": [],
			"fields": {
				"ComponentOfTotal": {
					"type": "IfcAppliedValue",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"Components": {
					"type": "IfcAppliedValue",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"ArithmeticOperator": {
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
				}
			}
		},
		"IfcApproval": {
			"domain": "ifcapprovalresource",
			"superclasses": [],
			"fields": {
				"Description": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ApprovalDateTime": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ApprovalStatus": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ApprovalLevel": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ApprovalQualifier": {
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
				"Identifier": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Actors": {
					"type": "IfcApprovalActorRelationship",
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
		"IfcApprovalActorRelationship": {
			"domain": "ifcapprovalresource",
			"superclasses": [],
			"fields": {
				"Actor": {
					"type": "IfcActorSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"Approval": {
					"type": "IfcApproval",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"Role": {
					"type": "IfcActorRole",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcApprovalPropertyRelationship": {
			"domain": "ifcapprovalresource",
			"superclasses": [],
			"fields": {
				"ApprovedProperties": {
					"type": "IfcProperty",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"Approval": {
					"type": "IfcApproval",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcApprovalRelationship": {
			"domain": "ifcapprovalresource",
			"superclasses": [],
			"fields": {
				"RelatedApproval": {
					"type": "IfcApproval",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatingApproval": {
					"type": "IfcApproval",
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
				"Name": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
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
				"AssetID": {
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
					"type": "IfcCalendarDate",
					"reference": true,
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
				"IfcIShapeProfileDef"
			],
			"fields": {
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
				"CentreOfGravityInY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInYAsString": {
					"type": "string",
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
					"type": "boolean",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SelfIntersect": {
					"type": "boolean",
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
		"IfcBezierCurve": {
			"domain": "ifcgeometryresource",
			"superclasses": [
				"IfcBSplineCurve"
			],
			"fields": {}
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
					"type": "enum",
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
		"IfcBoundaryEdgeCondition": {
			"domain": "ifcstructuralloadresource",
			"superclasses": [
				"IfcBoundaryCondition"
			],
			"fields": {
				"LinearStiffnessByLengthX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByLengthXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByLengthY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByLengthYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByLengthZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByLengthZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessByLengthX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessByLengthXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessByLengthY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessByLengthYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessByLengthZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessByLengthZAsString": {
					"type": "string",
					"reference": false,
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
				"LinearStiffnessByAreaX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByAreaXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByAreaY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByAreaYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByAreaZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessByAreaZAsString": {
					"type": "string",
					"reference": false,
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
				"LinearStiffnessX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LinearStiffnessZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RotationalStiffnessZAsString": {
					"type": "string",
					"reference": false,
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
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WarpingStiffnessAsString": {
					"type": "string",
					"reference": false,
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
		"IfcBuildingElementComponent": {
			"domain": "ifcstructuralelementsdomain",
			"superclasses": [
				"IfcBuildingElement"
			],
			"fields": {}
		},
		"IfcBuildingElementPart": {
			"domain": "ifcstructuralelementsdomain",
			"superclasses": [
				"IfcBuildingElementComponent"
			],
			"fields": {}
		},
		"IfcBuildingElementProxy": {
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcBuildingElement"
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
		"IfcBuildingElementProxyType": {
			"domain": "ifcproductextension",
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
				},
				"CentreOfGravityInX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInXAsString": {
					"type": "string",
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
		"IfcCalendarDate": {
			"domain": "ifcdatetimeresource",
			"superclasses": [
				"IfcDateTimeSelect",
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"DayComponent": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MonthComponent": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"YearComponent": {
					"type": "long",
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
		"IfcChamferEdgeFeature": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcEdgeFeature"
			],
			"fields": {
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
		"IfcClassification": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [],
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
					"type": "IfcCalendarDate",
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
				"Contains": {
					"type": "IfcClassificationItem",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcClassificationItem": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [],
			"fields": {
				"Notation": {
					"type": "IfcClassificationNotationFacet",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ItemOf": {
					"type": "IfcClassification",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"Title": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"IsClassifiedItemIn": {
					"type": "IfcClassificationItemRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"IsClassifyingItemIn": {
					"type": "IfcClassificationItemRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcClassificationItemRelationship": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [],
			"fields": {
				"RelatingItem": {
					"type": "IfcClassificationItem",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatedItems": {
					"type": "IfcClassificationItem",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcClassificationNotation": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [
				"IfcClassificationNotationSelect"
			],
			"fields": {
				"NotationFacets": {
					"type": "IfcClassificationNotationFacet",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcClassificationNotationFacet": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [],
			"fields": {
				"NotationValue": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcClassificationReference": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [
				"IfcExternalReference",
				"IfcClassificationNotationSelect"
			],
			"fields": {
				"ReferencedSource": {
					"type": "IfcClassification",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcClosedShell": {
			"domain": "ifctopologyresource",
			"superclasses": [
				"IfcConnectedFaceSet",
				"IfcShell"
			],
			"fields": {}
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
			"domain": "ifcpresentationresource",
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
		"IfcColourSpecification": {
			"domain": "ifcpresentationresource",
			"superclasses": [
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
					"type": "boolean",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
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
		"IfcCondition": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcGroup"
			],
			"fields": {}
		},
		"IfcConditionCriterion": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"Criterion": {
					"type": "IfcConditionCriterionSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"CriterionDateTime": {
					"type": "IfcDateTimeSelect",
					"reference": true,
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
		"IfcConnectionPortGeometry": {
			"domain": "ifcgeometricconstraintresource",
			"superclasses": [
				"IfcConnectionGeometry"
			],
			"fields": {
				"LocationAtRelatingElement": {
					"type": "IfcAxis2Placement",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"LocationAtRelatedElement": {
					"type": "IfcAxis2Placement",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ProfileOfPort": {
					"type": "IfcProfileDef",
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
		"IfcConstraint": {
			"domain": "ifcconstraintresource",
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
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"UserDefinedGrade": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ClassifiedAs": {
					"type": "IfcConstraintClassificationRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"RelatesConstraints": {
					"type": "IfcConstraintRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"IsRelatedWith": {
					"type": "IfcConstraintRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"PropertiesForConstraint": {
					"type": "IfcPropertyConstraintRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"Aggregates": {
					"type": "IfcConstraintAggregationRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"IsAggregatedIn": {
					"type": "IfcConstraintAggregationRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcConstraintAggregationRelationship": {
			"domain": "ifcconstraintresource",
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
				"RelatingConstraint": {
					"type": "IfcConstraint",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatedConstraints": {
					"type": "IfcConstraint",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"LogicalAggregator": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcConstraintClassificationRelationship": {
			"domain": "ifcconstraintresource",
			"superclasses": [],
			"fields": {
				"ClassifiedConstraint": {
					"type": "IfcConstraint",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatedClassifications": {
					"type": "IfcClassificationNotationSelect",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcConstraintRelationship": {
			"domain": "ifcconstraintresource",
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
				"RelatingConstraint": {
					"type": "IfcConstraint",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatedConstraints": {
					"type": "IfcConstraint",
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
			"fields": {}
		},
		"IfcConstructionMaterialResource": {
			"domain": "ifcconstructionmgmtdomain",
			"superclasses": [
				"IfcConstructionResource"
			],
			"fields": {
				"Suppliers": {
					"type": "IfcActorSelect",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"UsageRatio": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UsageRatioAsString": {
					"type": "string",
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
			"fields": {}
		},
		"IfcConstructionResource": {
			"domain": "ifcconstructionmgmtdomain",
			"superclasses": [
				"IfcResource"
			],
			"fields": {
				"ResourceIdentifier": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ResourceGroup": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ResourceConsumption": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseQuantity": {
					"type": "IfcMeasureWithUnit",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcContextDependentUnit": {
			"domain": "ifcmeasureresource",
			"superclasses": [
				"IfcNamedUnit"
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
		"IfcControl": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcObject"
			],
			"fields": {
				"Controls": {
					"type": "IfcRelAssignsToControl",
					"reference": true,
					"many": true,
					"inverse": true
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
				"IfcNamedUnit"
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
		"IfcCoordinatedUniversalTimeOffset": {
			"domain": "ifcdatetimeresource",
			"superclasses": [],
			"fields": {
				"HourOffset": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinuteOffset": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Sense": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcCostItem": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcControl"
			],
			"fields": {}
		},
		"IfcCostSchedule": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"SubmittedBy": {
					"type": "IfcActorSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"PreparedBy": {
					"type": "IfcActorSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"SubmittedOn": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"Status": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TargetUsers": {
					"type": "IfcActorSelect",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"UpdateDate": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ID": {
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
		"IfcCostValue": {
			"domain": "ifccostresource",
			"superclasses": [
				"IfcAppliedValue",
				"IfcMetricValueSelect"
			],
			"fields": {
				"CostType": {
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
				}
			}
		},
		"IfcCovering": {
			"domain": "ifcproductextension",
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
				"Covers": {
					"type": "IfcRelCoversBldgElements",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcCoveringType": {
			"domain": "ifcproductextension",
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
		"IfcCraneRailAShapeProfileDef": {
			"domain": "ifcprofileresource",
			"superclasses": [
				"IfcParameterizedProfileDef"
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
				"BaseWidth2": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseWidth2AsString": {
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
				},
				"HeadWidth": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadWidthAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth2": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth2AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth3": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth3AsString": {
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
				"BaseWidth4": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseWidth4AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth1": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth1AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth2": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth2AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth3": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth3AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcCraneRailFShapeProfileDef": {
			"domain": "ifcprofileresource",
			"superclasses": [
				"IfcParameterizedProfileDef"
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
				"HeadWidth": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadWidthAsString": {
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
				},
				"HeadDepth2": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth2AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth3": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HeadDepth3AsString": {
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
				"BaseDepth1": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth1AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth2": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BaseDepth2AsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInYAsString": {
					"type": "string",
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
			"fields": {}
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
			"superclasses": [],
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
					"type": "IfcDateAndTime",
					"reference": true,
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
			"fields": {}
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
				},
				"Dim": {
					"type": "long",
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
				}
			}
		},
		"IfcCurveStyleFont": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
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
			"superclasses": [],
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
		"IfcDateAndTime": {
			"domain": "ifcdatetimeresource",
			"superclasses": [
				"IfcDateTimeSelect",
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"DateComponent": {
					"type": "IfcCalendarDate",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"TimeComponent": {
					"type": "IfcLocalTime",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcDefinedSymbol": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcGeometricRepresentationItem"
			],
			"fields": {
				"Definition": {
					"type": "IfcDefinedSymbolSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"Target": {
					"type": "IfcCartesianTransformationOperator2D",
					"reference": true,
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
		"IfcDiameterDimension": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDimensionCurveDirectedCallout"
			],
			"fields": {}
		},
		"IfcDimensionCalloutRelationship": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDraughtingCalloutRelationship"
			],
			"fields": {}
		},
		"IfcDimensionCurve": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcAnnotationCurveOccurrence"
			],
			"fields": {
				"AnnotatedBySymbols": {
					"type": "IfcTerminatorSymbol",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcDimensionCurveDirectedCallout": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDraughtingCallout"
			],
			"fields": {}
		},
		"IfcDimensionCurveTerminator": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcTerminatorSymbol"
			],
			"fields": {
				"Role": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcDimensionPair": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDraughtingCalloutRelationship"
			],
			"fields": {}
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
				"IfcOrientationSelect",
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
			"fields": {}
		},
		"IfcDiscreteAccessoryType": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcElementComponentType"
			],
			"fields": {}
		},
		"IfcDistributionChamberElement": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcDistributionFlowElement"
			],
			"fields": {}
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
		"IfcDistributionControlElement": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcDistributionElement"
			],
			"fields": {
				"ControlElementId": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
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
			"fields": {}
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
				}
			}
		},
		"IfcDocumentElectronicFormat": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [],
			"fields": {
				"FileExtension": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MimeContentType": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MimeSubtype": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcDocumentInformation": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [
				"IfcDocumentSelect"
			],
			"fields": {
				"DocumentId": {
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
				"DocumentReferences": {
					"type": "IfcDocumentReference",
					"reference": true,
					"many": true,
					"inverse": true
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
					"type": "IfcDateAndTime",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"LastRevisionTime": {
					"type": "IfcDateAndTime",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ElectronicFormat": {
					"type": "IfcDocumentElectronicFormat",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ValidFrom": {
					"type": "IfcCalendarDate",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ValidUntil": {
					"type": "IfcCalendarDate",
					"reference": true,
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
			"superclasses": [],
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
				"ReferenceToDocument": {
					"type": "IfcDocumentInformation",
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
				}
			}
		},
		"IfcDoorLiningProperties": {
			"domain": "ifcsharedbldgelements",
			"superclasses": [
				"IfcPropertySetDefinition"
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
				}
			}
		},
		"IfcDoorPanelProperties": {
			"domain": "ifcsharedbldgelements",
			"superclasses": [
				"IfcPropertySetDefinition"
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
		"IfcDoorStyle": {
			"domain": "ifcsharedbldgelements",
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
		"IfcDraughtingCallout": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcGeometricRepresentationItem"
			],
			"fields": {
				"Contents": {
					"type": "IfcDraughtingCalloutElement",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"IsRelatedFromCallout": {
					"type": "IfcDraughtingCalloutRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"IsRelatedToCallout": {
					"type": "IfcDraughtingCalloutRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcDraughtingCalloutRelationship": {
			"domain": "ifcpresentationdimensioningresource",
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
				"RelatingDraughtingCallout": {
					"type": "IfcDraughtingCallout",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatedDraughtingCallout": {
					"type": "IfcDraughtingCallout",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcDraughtingPreDefinedColour": {
			"domain": "ifcpresentationresource",
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
		"IfcDraughtingPreDefinedTextFont": {
			"domain": "ifcpresentationresource",
			"superclasses": [
				"IfcPreDefinedTextFont"
			],
			"fields": {}
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
		"IfcEdgeFeature": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcFeatureElementSubtraction"
			],
			"fields": {
				"FeatureLength": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FeatureLengthAsString": {
					"type": "string",
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
		"IfcElectricDistributionPoint": {
			"domain": "ifcelectricaldomain",
			"superclasses": [
				"IfcFlowController"
			],
			"fields": {
				"DistributionPointFunction": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UserDefinedFunction": {
					"type": "string",
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
		"IfcElectricHeaterType": {
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
		"IfcElectricalBaseProperties": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcEnergyProperties"
			],
			"fields": {
				"ElectricCurrentType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InputVoltage": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InputVoltageAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InputFrequency": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InputFrequencyAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FullLoadCurrent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FullLoadCurrentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumCircuitCurrent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumCircuitCurrentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumPowerInput": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumPowerInputAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RatedPowerInput": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RatedPowerInputAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InputPhase": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcElectricalCircuit": {
			"domain": "ifcelectricaldomain",
			"superclasses": [
				"IfcSystem"
			],
			"fields": {}
		},
		"IfcElectricalElement": {
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcElement"
			],
			"fields": {}
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
				"HasStructuralMember": {
					"type": "IfcRelConnectsStructuralElement",
					"reference": true,
					"many": true,
					"inverse": true
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
				"HasCoverings": {
					"type": "IfcRelCoversBldgElements",
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
				"HasPorts": {
					"type": "IfcRelConnectsPortToElement",
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
				"IfcPropertySetDefinition"
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
				},
				"Dim": {
					"type": "long",
					"reference": false,
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
		"IfcEnergyProperties": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcPropertySetDefinition"
			],
			"fields": {
				"EnergySequence": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UserDefinedEnergySequence": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcEnvironmentalImpactValue": {
			"domain": "ifccostresource",
			"superclasses": [
				"IfcAppliedValue"
			],
			"fields": {
				"ImpactType": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Category": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UserDefinedCategory": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcEquipmentElement": {
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcElement"
			],
			"fields": {}
		},
		"IfcEquipmentStandard": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcControl"
			],
			"fields": {}
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
		"IfcExtendedMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"ExtendedProperties": {
					"type": "IfcProperty",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"Description": {
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
				}
			}
		},
		"IfcExternalReference": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [
				"IfcLightDistributionDataSourceSelect",
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"Location": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ItemReference": {
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
				}
			}
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
		"IfcExternallyDefinedSymbol": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcExternalReference",
				"IfcDefinedSymbolSelect"
			],
			"fields": {}
		},
		"IfcExternallyDefinedTextFont": {
			"domain": "ifcpresentationresource",
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
				"IfcManifoldSolidBrep"
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
			"fields": {}
		},
		"IfcFastenerType": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcElementComponentType"
			],
			"fields": {}
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
		"IfcFillAreaStyleTileSymbolWithStyle": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcGeometricRepresentationItem",
				"IfcFillAreaStyleTileShapeSelect"
			],
			"fields": {
				"Symbol": {
					"type": "IfcAnnotationSymbolOccurrence",
					"reference": true,
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
					"type": "IfcOneDirectionRepeatFactor",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"Tiles": {
					"type": "IfcFillAreaStyleTileShapeSelect",
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
		"IfcFluidFlowProperties": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcPropertySetDefinition"
			],
			"fields": {
				"PropertySource": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FlowConditionTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"VelocityTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"FlowrateTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"Fluid": {
					"type": "IfcMaterial",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"PressureTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"UserDefinedPropertySource": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TemperatureSingleValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TemperatureSingleValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WetBulbTemperatureSingleValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WetBulbTemperatureSingleValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WetBulbTemperatureTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"TemperatureTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"FlowrateSingleValue": {
					"type": "IfcDerivedMeasureValue",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"FlowConditionSingleValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FlowConditionSingleValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VelocitySingleValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VelocitySingleValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PressureSingleValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PressureSingleValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
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
		"IfcFuelProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"CombustionTemperature": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CombustionTemperatureAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CarbonContent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CarbonContentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LowerHeatingValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LowerHeatingValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HigherHeatingValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HigherHeatingValueAsString": {
					"type": "string",
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
		"IfcFurnitureStandard": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcControl"
			],
			"fields": {}
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
				}
			}
		},
		"IfcGasTerminalType": {
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
		"IfcGeneralMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"MolecularWeight": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MolecularWeightAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Porosity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PorosityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MassDensity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MassDensityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcGeneralProfileProperties": {
			"domain": "ifcprofilepropertyresource",
			"superclasses": [
				"IfcProfileProperties"
			],
			"fields": {
				"PhysicalWeight": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PhysicalWeightAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Perimeter": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PerimeterAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumPlateThickness": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumPlateThicknessAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumPlateThickness": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumPlateThicknessAsString": {
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
				"IfcRepresentationContext"
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
					"type": "IfcVirtualGridIntersection",
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
					"many": false,
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
		"IfcHygroscopicMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"UpperVaporResistanceFactor": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UpperVaporResistanceFactorAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LowerVaporResistanceFactor": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LowerVaporResistanceFactorAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"IsothermalMoistureCapacity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"IsothermalMoistureCapacityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VaporPermeability": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VaporPermeabilityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MoistureDiffusivity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MoistureDiffusivityAsString": {
					"type": "string",
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
				}
			}
		},
		"IfcImageTexture": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcSurfaceTexture"
			],
			"fields": {
				"UrlReference": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcInventory": {
			"domain": "ifcsharedfacilitieselements",
			"superclasses": [
				"IfcGroup"
			],
			"fields": {
				"InventoryType": {
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
					"type": "IfcCalendarDate",
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
				"OriginalValue": {
					"type": "IfcCostValue",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcIrregularTimeSeries": {
			"domain": "ifctimeseriesresource",
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
			"domain": "ifctimeseriesresource",
			"superclasses": [],
			"fields": {
				"TimeStamp": {
					"type": "IfcDateTimeSelect",
					"reference": true,
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
				},
				"CentreOfGravityInX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInYAsString": {
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
				"SkillSet": {
					"type": "string",
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
					"type": "IfcOrganization",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"VersionDate": {
					"type": "IfcCalendarDate",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"LibraryReference": {
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
				"ReferenceIntoLibrary": {
					"type": "IfcLibraryInformation",
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
		"IfcLinearDimension": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDimensionCurveDirectedCallout"
			],
			"fields": {}
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
		"IfcLocalTime": {
			"domain": "ifcdatetimeresource",
			"superclasses": [
				"IfcDateTimeSelect",
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"HourComponent": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinuteComponent": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SecondComponent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SecondComponentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Zone": {
					"type": "IfcCoordinatedUniversalTimeOffset",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"DaylightSavingOffset": {
					"type": "long",
					"reference": false,
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
				"IfcMaterialSelect",
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"Name": {
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
				"ClassifiedAs": {
					"type": "IfcMaterialClassificationRelationship",
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
					"type": "IfcClassificationNotationSelect",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"ClassifiedMaterial": {
					"type": "IfcMaterial",
					"reference": true,
					"many": false,
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
				"IfcMaterialSelect",
				"IfcObjectReferenceSelect"
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
				"IfcMaterialSelect"
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
				"IfcMaterialSelect"
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
				}
			}
		},
		"IfcMaterialList": {
			"domain": "ifcmaterialresource",
			"superclasses": [
				"IfcMaterialSelect",
				"IfcObjectReferenceSelect"
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
		"IfcMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [],
			"fields": {
				"Material": {
					"type": "IfcMaterial",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcMeasureWithUnit": {
			"domain": "ifcmeasureresource",
			"superclasses": [
				"IfcAppliedValueSelect",
				"IfcConditionCriterionSelect",
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
		"IfcMechanicalConcreteMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMechanicalMaterialProperties"
			],
			"fields": {
				"CompressiveStrength": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CompressiveStrengthAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaxAggregateSize": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaxAggregateSizeAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"AdmixturesDescription": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Workability": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ProtectivePoreRatio": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ProtectivePoreRatioAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WaterImpermeability": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcMechanicalFastener": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcFastener"
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
				}
			}
		},
		"IfcMechanicalFastenerType": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcFastenerType"
			],
			"fields": {}
		},
		"IfcMechanicalMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"DynamicViscosity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DynamicViscosityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"YoungModulus": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"YoungModulusAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearModulus": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearModulusAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PoissonRatio": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PoissonRatioAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalExpansionCoefficient": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalExpansionCoefficientAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcMechanicalSteelMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMechanicalMaterialProperties"
			],
			"fields": {
				"YieldStress": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"YieldStressAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UltimateStress": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UltimateStressAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UltimateStrain": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UltimateStrainAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HardeningModule": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HardeningModuleAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ProportionalStress": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ProportionalStressAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PlasticStrain": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PlasticStrainAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Relaxations": {
					"type": "IfcRelaxation",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcMember": {
			"domain": "ifcsharedbldgelements",
			"superclasses": [
				"IfcBuildingElement"
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
				}
			}
		},
		"IfcMonetaryUnit": {
			"domain": "ifcmeasureresource",
			"superclasses": [
				"IfcUnit"
			],
			"fields": {
				"Currency": {
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
		"IfcMove": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcTask"
			],
			"fields": {
				"MoveFrom": {
					"type": "IfcSpatialStructureElement",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"MoveTo": {
					"type": "IfcSpatialStructureElement",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"PunchList": {
					"type": "string",
					"reference": false,
					"many": true,
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
				"IsDefinedBy": {
					"type": "IfcRelDefines",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcObjectDefinition": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRoot"
			],
			"fields": {
				"HasAssignments": {
					"type": "IfcRelAssigns",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"IsDecomposedBy": {
					"type": "IfcRelDecomposes",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"Decomposes": {
					"type": "IfcRelDecomposes",
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
					"type": "IfcMetric",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ResultValues": {
					"type": "IfcMetric",
					"reference": true,
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
					"type": "boolean",
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
					"type": "boolean",
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
		"IfcOneDirectionRepeatFactor": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcGeometricRepresentationItem",
				"IfcHatchLineDistanceSelect"
			],
			"fields": {
				"RepeatFactor": {
					"type": "IfcVector",
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
				"HasFillings": {
					"type": "IfcRelFillsElement",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcOpticalMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"VisibleTransmittance": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VisibleTransmittanceAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SolarTransmittance": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SolarTransmittanceAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalIrTransmittance": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalIrTransmittanceAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalIrEmissivityBack": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalIrEmissivityBackAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalIrEmissivityFront": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalIrEmissivityFrontAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VisibleReflectanceBack": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VisibleReflectanceBackAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VisibleReflectanceFront": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VisibleReflectanceFrontAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SolarReflectanceFront": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SolarReflectanceFrontAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SolarReflectanceBack": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SolarReflectanceBackAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcOrderAction": {
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcTask"
			],
			"fields": {
				"ActionID": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcOrganization": {
			"domain": "ifcactorresource",
			"superclasses": [
				"IfcActorSelect",
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"Id": {
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
				}
			}
		},
		"IfcPermeableCoveringProperties": {
			"domain": "ifcarchitecturedomain",
			"superclasses": [
				"IfcPropertySetDefinition"
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
			"domain": "ifcfacilitiesmgmtdomain",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"PermitID": {
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
				"IfcObjectReferenceSelect"
			],
			"fields": {
				"Id": {
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
				"IfcObjectReferenceSelect"
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
			"domain": "ifcpresentationresource",
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
			"domain": "ifcpresentationresource",
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
					"many": false,
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
			"domain": "ifcpresentationresource",
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
		"IfcPreDefinedDimensionSymbol": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcPreDefinedSymbol"
			],
			"fields": {}
		},
		"IfcPreDefinedItem": {
			"domain": "ifcpresentationresource",
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
		"IfcPreDefinedPointMarkerSymbol": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcPreDefinedSymbol"
			],
			"fields": {}
		},
		"IfcPreDefinedSymbol": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcPreDefinedItem",
				"IfcDefinedSymbolSelect"
			],
			"fields": {}
		},
		"IfcPreDefinedTerminatorSymbol": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcPreDefinedSymbol"
			],
			"fields": {}
		},
		"IfcPreDefinedTextFont": {
			"domain": "ifcpresentationresource",
			"superclasses": [
				"IfcPreDefinedItem",
				"IfcTextFontSelect"
			],
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
					"type": "boolean",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LayerFrozen": {
					"type": "boolean",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LayerBlocked": {
					"type": "boolean",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LayerStyles": {
					"type": "IfcPresentationStyleSelect",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcPresentationStyle": {
			"domain": "ifcpresentationappearanceresource",
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
		"IfcPresentationStyleAssignment": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [],
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
				"ProcedureID": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ProcedureType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UserDefinedProcedureType": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcProcess": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcObject"
			],
			"fields": {
				"OperatesOn": {
					"type": "IfcRelAssignsToProcess",
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
				"IsPredecessorTo": {
					"type": "IfcRelSequence",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcProduct": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcObject"
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
				"IfcProductRepresentation"
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
		"IfcProductsOfCombustionProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"SpecificHeatCapacity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SpecificHeatCapacityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"N20Content": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"N20ContentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"COContent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"COContentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CO2Content": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CO2ContentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcProfileDef": {
			"domain": "ifcprofileresource",
			"superclasses": [],
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
				}
			}
		},
		"IfcProfileProperties": {
			"domain": "ifcprofilepropertyresource",
			"superclasses": [],
			"fields": {
				"ProfileName": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ProfileDefinition": {
					"type": "IfcProfileDef",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcProject": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcObject"
			],
			"fields": {
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
				}
			}
		},
		"IfcProjectOrder": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"ID": {
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
				"Status": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcProjectOrderRecord": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"Records": {
					"type": "IfcRelAssignsToProjectOrder",
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
		"IfcProjectionCurve": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcAnnotationCurveOccurrence"
			],
			"fields": {}
		},
		"IfcProjectionElement": {
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcFeatureElementAddition"
			],
			"fields": {}
		},
		"IfcProperty": {
			"domain": "ifcpropertyresource",
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
				}
			}
		},
		"IfcPropertyConstraintRelationship": {
			"domain": "ifcconstraintresource",
			"superclasses": [],
			"fields": {
				"RelatingConstraint": {
					"type": "IfcConstraint",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatedProperties": {
					"type": "IfcProperty",
					"reference": true,
					"many": true,
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
		"IfcPropertyDefinition": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRoot"
			],
			"fields": {
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
			"superclasses": [],
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
			"superclasses": [],
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
					"inverse": false
				}
			}
		},
		"IfcPropertySetDefinition": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcPropertyDefinition"
			],
			"fields": {
				"PropertyDefinitionOf": {
					"type": "IfcRelDefinesByProperties",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"DefinesType": {
					"type": "IfcTypeObject",
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
				}
			}
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
				}
			}
		},
		"IfcRadiusDimension": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDimensionCurveDirectedCallout"
			],
			"fields": {}
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
				"ShapeType": {
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
			"fields": {}
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
		"IfcRationalBezierCurve": {
			"domain": "ifcgeometryresource",
			"superclasses": [
				"IfcBezierCurve"
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
				},
				"Dim": {
					"type": "long",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcReferencesValueDocument": {
			"domain": "ifccostresource",
			"superclasses": [],
			"fields": {
				"ReferencedDocument": {
					"type": "IfcDocumentSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ReferencingValues": {
					"type": "IfcAppliedValue",
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
				}
			}
		},
		"IfcRegularTimeSeries": {
			"domain": "ifctimeseriesresource",
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
			"domain": "ifcprofilepropertyresource",
			"superclasses": [],
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
				"IfcPropertySetDefinition"
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
				"BarRole": {
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
		"IfcReinforcingElement": {
			"domain": "ifcstructuralelementsdomain",
			"superclasses": [
				"IfcBuildingElementComponent"
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
				}
			}
		},
		"IfcRelAggregates": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelDecomposes"
			],
			"fields": {}
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
		"IfcRelAssignsTasks": {
			"domain": "ifcprocessextension",
			"superclasses": [
				"IfcRelAssignsToControl"
			],
			"fields": {
				"TimeForTask": {
					"type": "IfcScheduleTimeControl",
					"reference": true,
					"many": false,
					"inverse": true
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
		"IfcRelAssignsToProcess": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelAssigns"
			],
			"fields": {
				"RelatingProcess": {
					"type": "IfcProcess",
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
					"type": "IfcProduct",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcRelAssignsToProjectOrder": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcRelAssignsToControl"
			],
			"fields": {}
		},
		"IfcRelAssignsToResource": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelAssigns"
			],
			"fields": {
				"RelatingResource": {
					"type": "IfcResource",
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
					"type": "IfcRoot",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcRelAssociatesAppliedValue": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcRelAssociates"
			],
			"fields": {
				"RelatingAppliedValue": {
					"type": "IfcAppliedValue",
					"reference": true,
					"many": false,
					"inverse": false
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
					"inverse": false
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
					"type": "IfcClassificationNotationSelect",
					"reference": true,
					"many": false,
					"inverse": false
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
					"inverse": false
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
					"inverse": false
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
					"inverse": false
				}
			}
		},
		"IfcRelAssociatesProfileProperties": {
			"domain": "ifcstructuralanalysisdomain",
			"superclasses": [
				"IfcRelAssociates"
			],
			"fields": {
				"RelatingProfileProperties": {
					"type": "IfcProfileProperties",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ProfileSectionLocation": {
					"type": "IfcShapeAspect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ProfileOrientation": {
					"type": "IfcOrientationSelect",
					"reference": true,
					"many": false,
					"inverse": false
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
					"type": "IfcElement",
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
		"IfcRelConnectsStructuralElement": {
			"domain": "ifcstructuralanalysisdomain",
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
				"RelatedStructuralMember": {
					"type": "IfcStructuralMember",
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
					"type": "IfcSpatialStructureElement",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcRelCoversBldgElements": {
			"domain": "ifcproductextension",
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
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcRelConnects"
			],
			"fields": {
				"RelatedSpace": {
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
		"IfcRelDecomposes": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelationship"
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
		"IfcRelDefines": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelationship"
			],
			"fields": {
				"RelatedObjects": {
					"type": "IfcObject",
					"reference": true,
					"many": true,
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
				"RelatingPropertyDefinition": {
					"type": "IfcPropertySetDefinition",
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
		"IfcRelInteractionRequirements": {
			"domain": "ifcarchitecturedomain",
			"superclasses": [
				"IfcRelConnects"
			],
			"fields": {
				"DailyInteraction": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DailyInteractionAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ImportanceRating": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ImportanceRatingAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"LocationOfInteraction": {
					"type": "IfcSpatialStructureElement",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"RelatedSpaceProgram": {
					"type": "IfcSpaceProgram",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"RelatingSpaceProgram": {
					"type": "IfcSpaceProgram",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcRelNests": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelDecomposes"
			],
			"fields": {}
		},
		"IfcRelOccupiesSpaces": {
			"domain": "ifcsharedfacilitieselements",
			"superclasses": [
				"IfcRelAssignsToActor"
			],
			"fields": {}
		},
		"IfcRelOverridesProperties": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcRelDefinesByProperties"
			],
			"fields": {
				"OverridingProperties": {
					"type": "IfcProperty",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcRelProjectsElement": {
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
					"type": "IfcSpatialStructureElement",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcRelSchedulesCostItems": {
			"domain": "ifcsharedmgmtelements",
			"superclasses": [
				"IfcRelAssignsToControl"
			],
			"fields": {}
		},
		"IfcRelSequence": {
			"domain": "ifckernel",
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
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TimeLagAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SequenceType": {
					"type": "enum",
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
					"type": "IfcSpatialStructureElement",
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
					"type": "IfcSpace",
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
		"IfcRelVoidsElement": {
			"domain": "ifcproductextension",
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
		"IfcRelaxation": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [],
			"fields": {
				"RelaxationValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RelaxationValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InitialStress": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"InitialStressAsString": {
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
				"LayerAssignments": {
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
			"superclasses": [],
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
				"IfcObject"
			],
			"fields": {
				"ResourceOf": {
					"type": "IfcRelAssignsToResource",
					"reference": true,
					"many": true,
					"inverse": true
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
		"IfcRibPlateProfileProperties": {
			"domain": "ifcprofilepropertyresource",
			"superclasses": [
				"IfcProfileProperties"
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
				},
				"RibHeight": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RibHeightAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RibWidth": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RibWidthAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RibSpacing": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RibSpacingAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Direction": {
					"type": "enum",
					"reference": false,
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
				"ShapeType": {
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
		"IfcRoundedEdgeFeature": {
			"domain": "ifcsharedcomponentelements",
			"superclasses": [
				"IfcEdgeFeature"
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
		"IfcScheduleTimeControl": {
			"domain": "ifcprocessextension",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"ActualStart": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"EarlyStart": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"LateStart": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ScheduleStart": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ActualFinish": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"EarlyFinish": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"LateFinish": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ScheduleFinish": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"ScheduleDuration": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ScheduleDurationAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ActualDuration": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ActualDurationAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RemainingTime": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RemainingTimeAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FreeFloat": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FreeFloatAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TotalFloat": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TotalFloatAsString": {
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
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"StartFloat": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"StartFloatAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FinishFloat": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FinishFloatAsString": {
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
				},
				"ScheduleTimeControlAssigned": {
					"type": "IfcRelAssignsTasks",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
		},
		"IfcSectionProperties": {
			"domain": "ifcprofilepropertyresource",
			"superclasses": [],
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
			"domain": "ifcprofilepropertyresource",
			"superclasses": [],
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
		"IfcServiceLife": {
			"domain": "ifcsharedfacilitieselements",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"ServiceLifeType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ServiceLifeDuration": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ServiceLifeDurationAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcServiceLifeFactor": {
			"domain": "ifcsharedfacilitieselements",
			"superclasses": [
				"IfcPropertySetDefinition"
			],
			"fields": {
				"PredefinedType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UpperValue": {
					"type": "IfcMeasureValue",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"MostUsedValue": {
					"type": "IfcMeasureValue",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"LowerValue": {
					"type": "IfcMeasureValue",
					"reference": true,
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
					"type": "boolean",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PartOfProductDefinitionShape": {
					"type": "IfcProductDefinitionShape",
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
		"IfcSolidModel": {
			"domain": "ifcgeometricmodelresource",
			"superclasses": [
				"IfcGeometricRepresentationItem",
				"IfcBooleanOperand"
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
		"IfcSoundProperties": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcPropertySetDefinition"
			],
			"fields": {
				"IsAttenuating": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SoundScale": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SoundValues": {
					"type": "IfcSoundValue",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcSoundValue": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcPropertySetDefinition"
			],
			"fields": {
				"SoundLevelTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"Frequency": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FrequencyAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SoundLevelSingleValue": {
					"type": "IfcDerivedMeasureValue",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcSpace": {
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcSpatialStructureElement"
			],
			"fields": {
				"InteriorOrExteriorSpace": {
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
		"IfcSpaceHeaterType": {
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
		"IfcSpaceProgram": {
			"domain": "ifcarchitecturedomain",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"SpaceProgramIdentifier": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaxRequiredArea": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaxRequiredAreaAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinRequiredArea": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinRequiredAreaAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"RequestedLocation": {
					"type": "IfcSpatialStructureElement",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"StandardRequiredArea": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"StandardRequiredAreaAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HasInteractionReqsFrom": {
					"type": "IfcRelInteractionRequirements",
					"reference": true,
					"many": true,
					"inverse": true
				},
				"HasInteractionReqsTo": {
					"type": "IfcRelInteractionRequirements",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcSpaceThermalLoadProperties": {
			"domain": "ifcsharedbldgserviceelements",
			"superclasses": [
				"IfcPropertySetDefinition"
			],
			"fields": {
				"ApplicableValueRatio": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ApplicableValueRatioAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalLoadSource": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PropertySource": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SourceDescription": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumValue": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumValueAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalLoadTimeSeriesValues": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"UserDefinedThermalLoadSource": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UserDefinedPropertySource": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalLoadType": {
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
				}
			}
		},
		"IfcSpatialStructureElement": {
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
				"CompositionType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ReferencesElements": {
					"type": "IfcRelReferencedInSpatialStructure",
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
				"ContainsElements": {
					"type": "IfcRelContainedInSpatialStructure",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcSpatialStructureElementType": {
			"domain": "ifcproductextension",
			"superclasses": [
				"IfcElementType"
			],
			"fields": {}
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
				"ShapeType": {
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
				"NumberOfRiser": {
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
				},
				"CausedBy": {
					"type": "IfcStructuralReaction",
					"reference": true,
					"many": false,
					"inverse": true
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
					"many": false,
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
		"IfcStructuralCurveConnection": {
			"domain": "ifcstructuralanalysisdomain",
			"superclasses": [
				"IfcStructuralConnection"
			],
			"fields": {}
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
				"IfcStructuralAction"
			],
			"fields": {
				"ProjectedOrTrue": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcStructuralLinearActionVarying": {
			"domain": "ifcstructuralanalysisdomain",
			"superclasses": [
				"IfcStructuralLinearAction"
			],
			"fields": {
				"VaryingAppliedLoadLocation": {
					"type": "IfcShapeAspect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"SubsequentAppliedLoads": {
					"type": "IfcStructuralLoad",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
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
				"IfcStructuralLoad"
			],
			"fields": {}
		},
		"IfcStructuralLoadTemperature": {
			"domain": "ifcstructuralloadresource",
			"superclasses": [
				"IfcStructuralLoadStatic"
			],
			"fields": {
				"DeltaT_Constant": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DeltaT_ConstantAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DeltaT_Y": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DeltaT_YAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DeltaT_Z": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DeltaT_ZAsString": {
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
				"ReferencesElement": {
					"type": "IfcRelConnectsStructuralElement",
					"reference": true,
					"many": true,
					"inverse": true
				},
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
				"IfcStructuralAction"
			],
			"fields": {
				"ProjectedOrTrue": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcStructuralPlanarActionVarying": {
			"domain": "ifcstructuralanalysisdomain",
			"superclasses": [
				"IfcStructuralPlanarAction"
			],
			"fields": {
				"VaryingAppliedLoadLocation": {
					"type": "IfcShapeAspect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"SubsequentAppliedLoads": {
					"type": "IfcStructuralLoad",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
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
			"fields": {}
		},
		"IfcStructuralPointReaction": {
			"domain": "ifcstructuralanalysisdomain",
			"superclasses": [
				"IfcStructuralReaction"
			],
			"fields": {}
		},
		"IfcStructuralProfileProperties": {
			"domain": "ifcprofilepropertyresource",
			"superclasses": [
				"IfcGeneralProfileProperties"
			],
			"fields": {
				"TorsionalConstantX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TorsionalConstantXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MomentOfInertiaYZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MomentOfInertiaYZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MomentOfInertiaY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MomentOfInertiaYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MomentOfInertiaZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MomentOfInertiaZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WarpingConstant": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"WarpingConstantAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearCentreZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearCentreZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearCentreY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearCentreYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearDeformationAreaZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearDeformationAreaZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearDeformationAreaY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearDeformationAreaYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumSectionModulusY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumSectionModulusYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumSectionModulusY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumSectionModulusYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumSectionModulusZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MaximumSectionModulusZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumSectionModulusZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"MinimumSectionModulusZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TorsionalSectionModulus": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TorsionalSectionModulusAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInXAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcStructuralReaction": {
			"domain": "ifcstructuralanalysisdomain",
			"superclasses": [
				"IfcStructuralActivity"
			],
			"fields": {
				"Causes": {
					"type": "IfcStructuralAction",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
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
		"IfcStructuralSteelProfileProperties": {
			"domain": "ifcprofilepropertyresource",
			"superclasses": [
				"IfcStructuralProfileProperties"
			],
			"fields": {
				"ShearAreaZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearAreaZAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearAreaY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ShearAreaYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PlasticShapeFactorY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PlasticShapeFactorYAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PlasticShapeFactorZ": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PlasticShapeFactorZAsString": {
					"type": "string",
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
			"fields": {
				"SubsequentThickness": {
					"type": "double",
					"reference": false,
					"many": true,
					"inverse": false
				},
				"SubsequentThicknessAsString": {
					"type": "string",
					"reference": false,
					"many": true,
					"inverse": false
				},
				"VaryingThicknessLocation": {
					"type": "IfcShapeAspect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"VaryingThickness": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"VaryingThicknessAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcStructuredDimensionCallout": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcDraughtingCallout"
			],
			"fields": {}
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
					"type": "IfcPresentationStyleAssignment",
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
				"SubContractor": {
					"type": "IfcActorSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"JobDescription": {
					"type": "string",
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
			"fields": {}
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
				},
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
				"IfcSurfaceStyleElementSelect"
			],
			"fields": {
				"SurfaceColour": {
					"type": "IfcColourRgb",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcSurfaceStyleWithTextures": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcSurfaceStyleElementSelect"
			],
			"fields": {
				"Textures": {
					"type": "IfcSurfaceTexture",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcSurfaceTexture": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [],
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
				"TextureType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TextureTransform": {
					"type": "IfcCartesianTransformationOperator2D",
					"reference": true,
					"many": false,
					"inverse": false
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
				},
				"Dim": {
					"type": "long",
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
		"IfcSymbolStyle": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcPresentationStyle",
				"IfcPresentationStyleSelect"
			],
			"fields": {
				"StyleOfSymbol": {
					"type": "IfcSymbolStyleSelect",
					"reference": true,
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
		"IfcSystemFurnitureElementType": {
			"domain": "ifcsharedfacilitieselements",
			"superclasses": [
				"IfcFurnishingElementType"
			],
			"fields": {}
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
				},
				"CentreOfGravityInY": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInYAsString": {
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
				"IfcMetricValueSelect"
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
					"inverse": true
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
				},
				"OfTable": {
					"type": "IfcTable",
					"reference": true,
					"many": false,
					"inverse": true
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
				"TaskId": {
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
			"fields": {}
		},
		"IfcTerminatorSymbol": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [
				"IfcAnnotationSymbolOccurrence"
			],
			"fields": {
				"AnnotatedCurve": {
					"type": "IfcAnnotationCurveOccurrence",
					"reference": true,
					"many": false,
					"inverse": true
				}
			}
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
					"type": "IfcCharacterStyleSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"TextStyle": {
					"type": "IfcTextStyleSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"TextFontStyle": {
					"type": "IfcTextFontSelect",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcTextStyleFontModel": {
			"domain": "ifcpresentationresource",
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
				"IfcCharacterStyleSelect"
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
				"IfcTextStyleSelect"
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
		"IfcTextStyleWithBoxCharacteristics": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcTextStyleSelect"
			],
			"fields": {
				"BoxHeight": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxHeightAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxWidth": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxWidthAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxSlantAngle": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxSlantAngleAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxRotateAngle": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoxRotateAngleAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CharacterSpacing": {
					"type": "IfcSizeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcTextureCoordinate": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [],
			"fields": {
				"AnnotatedSurface": {
					"type": "IfcAnnotationSurface",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcTextureCoordinateGenerator": {
			"domain": "ifcpresentationdefinitionresource",
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
					"type": "IfcSimpleValue",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcTextureMap": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [
				"IfcTextureCoordinate"
			],
			"fields": {
				"TextureMaps": {
					"type": "IfcVertexBasedTextureMap",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcTextureVertex": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [],
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
		"IfcThermalMaterialProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"SpecificHeatCapacity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"SpecificHeatCapacityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoilingPoint": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"BoilingPointAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FreezingPoint": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"FreezingPointAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalConductivity": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ThermalConductivityAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcTimeSeries": {
			"domain": "ifctimeseriesresource",
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
				"Description": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"StartTime": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"EndTime": {
					"type": "IfcDateTimeSelect",
					"reference": true,
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
				"DocumentedBy": {
					"type": "IfcTimeSeriesReferenceRelationship",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcTimeSeriesReferenceRelationship": {
			"domain": "ifctimeseriesresource",
			"superclasses": [],
			"fields": {
				"ReferencedTimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": true
				},
				"TimeSeriesReferences": {
					"type": "IfcDocumentSelect",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
		},
		"IfcTimeSeriesSchedule": {
			"domain": "ifccontrolextension",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"ApplicableDates": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"TimeSeriesScheduleType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TimeSeries": {
					"type": "IfcTimeSeries",
					"reference": true,
					"many": false,
					"inverse": false
				}
			}
		},
		"IfcTimeSeriesValue": {
			"domain": "ifctimeseriesresource",
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
				"OperationType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CapacityByWeight": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CapacityByWeightAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CapacityByNumber": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CapacityByNumberAsString": {
					"type": "string",
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
		"IfcTwoDirectionRepeatFactor": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [
				"IfcOneDirectionRepeatFactor"
			],
			"fields": {
				"SecondRepeatFactor": {
					"type": "IfcVector",
					"reference": true,
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
				"ObjectTypeOf": {
					"type": "IfcRelDefinesByType",
					"reference": true,
					"many": true,
					"inverse": true
				}
			}
		},
		"IfcTypeProduct": {
			"domain": "ifckernel",
			"superclasses": [
				"IfcTypeObject"
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
				},
				"CentreOfGravityInX": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CentreOfGravityInXAsString": {
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
		"IfcVertexBasedTextureMap": {
			"domain": "ifcpresentationdefinitionresource",
			"superclasses": [],
			"fields": {
				"TextureVertices": {
					"type": "IfcTextureVertex",
					"reference": true,
					"many": true,
					"inverse": false
				},
				"TexturePoints": {
					"type": "IfcCartesianPoint",
					"reference": true,
					"many": true,
					"inverse": false
				}
			}
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
		"IfcVibrationIsolatorType": {
			"domain": "ifchvacdomain",
			"superclasses": [
				"IfcDiscreteAccessoryType"
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
			"superclasses": [],
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
		"IfcWall": {
			"domain": "ifcsharedbldgelements",
			"superclasses": [
				"IfcBuildingElement"
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
		"IfcWaterProperties": {
			"domain": "ifcmaterialpropertyresource",
			"superclasses": [
				"IfcMaterialProperties"
			],
			"fields": {
				"IsPotable": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"Hardness": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"HardnessAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"AlkalinityConcentration": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"AlkalinityConcentrationAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"AcidityConcentration": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"AcidityConcentrationAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ImpuritiesContent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"ImpuritiesContentAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PHLevel": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"PHLevelAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DissolvedSolidsContent": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DissolvedSolidsContentAsString": {
					"type": "string",
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
				}
			}
		},
		"IfcWindowLiningProperties": {
			"domain": "ifcsharedbldgelements",
			"superclasses": [
				"IfcPropertySetDefinition"
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
				}
			}
		},
		"IfcWindowPanelProperties": {
			"domain": "ifcsharedbldgelements",
			"superclasses": [
				"IfcPropertySetDefinition"
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
		"IfcWindowStyle": {
			"domain": "ifcsharedbldgelements",
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
		"IfcWorkControl": {
			"domain": "ifcprocessextension",
			"superclasses": [
				"IfcControl"
			],
			"fields": {
				"Identifier": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"CreationDate": {
					"type": "IfcDateTimeSelect",
					"reference": true,
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
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"DurationAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TotalFloat": {
					"type": "double",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"TotalFloatAsString": {
					"type": "string",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"StartTime": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"FinishTime": {
					"type": "IfcDateTimeSelect",
					"reference": true,
					"many": false,
					"inverse": false
				},
				"WorkControlType": {
					"type": "enum",
					"reference": false,
					"many": false,
					"inverse": false
				},
				"UserDefinedControlType": {
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
			"fields": {}
		},
		"IfcWorkSchedule": {
			"domain": "ifcprocessextension",
			"superclasses": [
				"IfcWorkControl"
			],
			"fields": {}
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
				"IfcGroup"
			],
			"fields": {}
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
		"IfcBoolean": {
			"domain": "ifcmeasureresource",
			"superclasses": [
				"IfcSimpleValue",
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
		"IfcDaylightSavingHour": {
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
			"domain": "ifcpresentationresource",
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
			"domain": "ifcpresentationresource",
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
			"domain": "ifcpresentationresource",
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
		"IfcHourInDay": {
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
				"IfcConditionCriterionSelect",
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
		"IfcMinuteInHour": {
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
		"IfcModulusOfRotationalSubgradeReactionMeasure": {
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
		"IfcModulusOfSubgradeReactionMeasure": {
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
				"IfcAppliedValueSelect",
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
				"IfcMeasureValue",
				"IfcOrientationSelect"
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
			"domain": "ifcpresentationresource",
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
				"IfcAppliedValueSelect",
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
		"IfcSecondInMinute": {
			"domain": "ifcdatetimeresource",
			"superclasses": [],
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
		"IfcText": {
			"domain": "ifcmeasureresource",
			"superclasses": [
				"IfcMetricValueSelect",
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
			"domain": "ifcpresentationresource",
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
		"IfcYearNumber": {
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
		"IfcActionSourceTypeEnum": {},
		"IfcActionTypeEnum": {},
		"IfcActuatorTypeEnum": {},
		"IfcAddressTypeEnum": {},
		"IfcAheadOrBehind": {},
		"IfcAirTerminalBoxTypeEnum": {},
		"IfcAirTerminalTypeEnum": {},
		"IfcAirToAirHeatRecoveryTypeEnum": {},
		"IfcAlarmTypeEnum": {},
		"IfcAnalysisModelTypeEnum": {},
		"IfcAnalysisTheoryTypeEnum": {},
		"IfcArithmeticOperatorEnum": {},
		"IfcAssemblyPlaceEnum": {},
		"IfcBSplineCurveForm": {},
		"IfcBeamTypeEnum": {},
		"IfcBenchmarkEnum": {},
		"IfcBoilerTypeEnum": {},
		"IfcBooleanOperator": {},
		"IfcBuildingElementProxyTypeEnum": {},
		"IfcCableCarrierFittingTypeEnum": {},
		"IfcCableCarrierSegmentTypeEnum": {},
		"IfcCableSegmentTypeEnum": {},
		"IfcChangeActionEnum": {},
		"IfcChillerTypeEnum": {},
		"IfcCoilTypeEnum": {},
		"IfcColumnTypeEnum": {},
		"IfcCompressorTypeEnum": {},
		"IfcCondenserTypeEnum": {},
		"IfcConnectionTypeEnum": {},
		"IfcConstraintEnum": {},
		"IfcControllerTypeEnum": {},
		"IfcCooledBeamTypeEnum": {},
		"IfcCoolingTowerTypeEnum": {},
		"IfcCostScheduleTypeEnum": {},
		"IfcCoveringTypeEnum": {},
		"IfcCurrencyEnum": {},
		"IfcCurtainWallTypeEnum": {},
		"IfcDamperTypeEnum": {},
		"IfcDataOriginEnum": {},
		"IfcDerivedUnitEnum": {},
		"IfcDimensionExtentUsage": {},
		"IfcDirectionSenseEnum": {},
		"IfcDistributionChamberElementTypeEnum": {},
		"IfcDocumentConfidentialityEnum": {},
		"IfcDocumentStatusEnum": {},
		"IfcDoorPanelOperationEnum": {},
		"IfcDoorPanelPositionEnum": {},
		"IfcDoorStyleConstructionEnum": {},
		"IfcDoorStyleOperationEnum": {},
		"IfcDuctFittingTypeEnum": {},
		"IfcDuctSegmentTypeEnum": {},
		"IfcDuctSilencerTypeEnum": {},
		"IfcElectricApplianceTypeEnum": {},
		"IfcElectricCurrentEnum": {},
		"IfcElectricDistributionPointFunctionEnum": {},
		"IfcElectricFlowStorageDeviceTypeEnum": {},
		"IfcElectricGeneratorTypeEnum": {},
		"IfcElectricHeaterTypeEnum": {},
		"IfcElectricMotorTypeEnum": {},
		"IfcElectricTimeControlTypeEnum": {},
		"IfcElementAssemblyTypeEnum": {},
		"IfcElementCompositionEnum": {},
		"IfcEnergySequenceEnum": {},
		"IfcEnvironmentalImpactCategoryEnum": {},
		"IfcEvaporativeCoolerTypeEnum": {},
		"IfcEvaporatorTypeEnum": {},
		"IfcFanTypeEnum": {},
		"IfcFilterTypeEnum": {},
		"IfcFireSuppressionTerminalTypeEnum": {},
		"IfcFlowDirectionEnum": {},
		"IfcFlowInstrumentTypeEnum": {},
		"IfcFlowMeterTypeEnum": {},
		"IfcFootingTypeEnum": {},
		"IfcGasTerminalTypeEnum": {},
		"IfcGeometricProjectionEnum": {},
		"IfcGlobalOrLocalEnum": {},
		"IfcHeatExchangerTypeEnum": {},
		"IfcHumidifierTypeEnum": {},
		"IfcInternalOrExternalEnum": {},
		"IfcInventoryTypeEnum": {},
		"IfcJunctionBoxTypeEnum": {},
		"IfcLampTypeEnum": {},
		"IfcLayerSetDirectionEnum": {},
		"IfcLightDistributionCurveEnum": {},
		"IfcLightEmissionSourceEnum": {},
		"IfcLightFixtureTypeEnum": {},
		"IfcLoadGroupTypeEnum": {},
		"IfcLogicalOperatorEnum": {},
		"IfcMemberTypeEnum": {},
		"IfcMotorConnectionTypeEnum": {},
		"IfcNullStyleEnum": {},
		"IfcObjectTypeEnum": {},
		"IfcObjectiveEnum": {},
		"IfcOccupantTypeEnum": {},
		"IfcOutletTypeEnum": {},
		"IfcPermeableCoveringOperationEnum": {},
		"IfcPhysicalOrVirtualEnum": {},
		"IfcPileConstructionEnum": {},
		"IfcPileTypeEnum": {},
		"IfcPipeFittingTypeEnum": {},
		"IfcPipeSegmentTypeEnum": {},
		"IfcPlateTypeEnum": {},
		"IfcProcedureTypeEnum": {},
		"IfcProfileTypeEnum": {},
		"IfcProjectOrderRecordTypeEnum": {},
		"IfcProjectOrderTypeEnum": {},
		"IfcProjectedOrTrueLengthEnum": {},
		"IfcPropertySourceEnum": {},
		"IfcProtectiveDeviceTypeEnum": {},
		"IfcPumpTypeEnum": {},
		"IfcRailingTypeEnum": {},
		"IfcRampFlightTypeEnum": {},
		"IfcRampTypeEnum": {},
		"IfcReflectanceMethodEnum": {},
		"IfcReinforcingBarRoleEnum": {},
		"IfcReinforcingBarSurfaceEnum": {},
		"IfcResourceConsumptionEnum": {},
		"IfcRibPlateDirectionEnum": {},
		"IfcRoleEnum": {},
		"IfcRoofTypeEnum": {},
		"IfcSIPrefix": {},
		"IfcSIUnitName": {},
		"IfcSanitaryTerminalTypeEnum": {},
		"IfcSectionTypeEnum": {},
		"IfcSensorTypeEnum": {},
		"IfcSequenceEnum": {},
		"IfcServiceLifeFactorTypeEnum": {},
		"IfcServiceLifeTypeEnum": {},
		"IfcSlabTypeEnum": {},
		"IfcSoundScaleEnum": {},
		"IfcSpaceHeaterTypeEnum": {},
		"IfcSpaceTypeEnum": {},
		"IfcStackTerminalTypeEnum": {},
		"IfcStairFlightTypeEnum": {},
		"IfcStairTypeEnum": {},
		"IfcStateEnum": {},
		"IfcStructuralCurveTypeEnum": {},
		"IfcStructuralSurfaceTypeEnum": {},
		"IfcSurfaceSide": {},
		"IfcSurfaceTextureEnum": {},
		"IfcSwitchingDeviceTypeEnum": {},
		"IfcTankTypeEnum": {},
		"IfcTendonTypeEnum": {},
		"IfcTextPath": {},
		"IfcThermalLoadSourceEnum": {},
		"IfcThermalLoadTypeEnum": {},
		"IfcTimeSeriesDataTypeEnum": {},
		"IfcTimeSeriesScheduleTypeEnum": {},
		"IfcTransformerTypeEnum": {},
		"IfcTransitionCode": {},
		"IfcTransportElementTypeEnum": {},
		"IfcTrimmingPreference": {},
		"IfcTubeBundleTypeEnum": {},
		"IfcUnitEnum": {},
		"IfcUnitaryEquipmentTypeEnum": {},
		"IfcValveTypeEnum": {},
		"IfcVibrationIsolatorTypeEnum": {},
		"IfcWallTypeEnum": {},
		"IfcWasteTerminalTypeEnum": {},
		"IfcWindowPanelOperationEnum": {},
		"IfcWindowPanelPositionEnum": {},
		"IfcWindowStyleConstructionEnum": {},
		"IfcWindowStyleOperationEnum": {},
		"IfcWorkControlTypeEnum": {},
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
		"IfcBooleanOperand": {
			"domain": "ifcgeometricmodelresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcCharacterStyleSelect": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcClassificationNotationSelect": {
			"domain": "ifcexternalreferenceresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcColour": {
			"domain": "ifcpresentationresource",
			"superclasses": [
				"IfcFillStyleSelect",
				"IfcSymbolStyleSelect"
			],
			"fields": {}
		},
		"IfcColourOrFactor": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcConditionCriterionSelect": {
			"domain": "ifcfacilitiesmgmtdomain",
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
		"IfcDateTimeSelect": {
			"domain": "ifcdatetimeresource",
			"superclasses": [
				"IfcMetricValueSelect"
			],
			"fields": {}
		},
		"IfcDefinedSymbolSelect": {
			"domain": "ifcpresentationdefinitionresource",
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
		"IfcDraughtingCalloutElement": {
			"domain": "ifcpresentationdimensioningresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcFillAreaStyleTileShapeSelect": {
			"domain": "ifcpresentationappearanceresource",
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
		"IfcObjectReferenceSelect": {
			"domain": "ifcpropertyresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcOrientationSelect": {
			"domain": "ifcstructuralanalysisdomain",
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
		"IfcSymbolStyleSelect": {
			"domain": "ifcpresentationappearanceresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcTextFontSelect": {
			"domain": "ifcpresentationresource",
			"superclasses": [],
			"fields": {}
		},
		"IfcTextStyleSelect": {
			"domain": "ifcpresentationappearanceresource",
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
			"superclasses": [],
			"fields": {}
		},
		"IfcVectorOrDirection": {
			"domain": "ifcgeometryresource",
			"superclasses": [],
			"fields": {}
		}
	}
};