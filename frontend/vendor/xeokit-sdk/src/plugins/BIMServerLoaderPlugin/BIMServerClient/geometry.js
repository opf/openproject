/**
 * @private
 */
export const geometry = {
	"classes": {
		"Vector3f": {
			"domain": "bimserver",
			"superclasses": [],
			"fields": {
				"x": {
					"type": "float",
					"reference": false,
					"many": false
				},
				"y": {
					"type": "float",
					"reference": false,
					"many": false
				},
				"z": {
					"type": "float",
					"reference": false,
					"many": false
				},
			}
		},
		"GeometryData": {
			"domain": "bimserver",
			"superclasses": [],
			"fields": {}
		},
		"GeometryInfo": {
			"domain": "bimserver",
			"superclasses": [],
			"fields": {
				"minBounds": {
					"type": "Vector3f",
					"reference": true,
					"many": false
				},
				"maxBounds": {
					"type": "Vector3f",
					"reference": true,
					"many": false
				},
				"startVertex": {
					"type": "int",
					"reference": false,
					"many": false
				},
				"startIndex": {
					"type": "int",
					"reference": false,
					"many": false
				},
				"primitiveCount": {
					"type": "int",
					"reference": false,
					"many": false
				},
				"data": {
					"type": "GeometryData",
					"reference": true,
					"many": false
				},
				"transformation": {
					"type": "float",
					"reference": false,
					"many": true
				},
				"area": {
					"type": "float",
					"reference": false,
					"many": false
				},
				"volume": {
					"type": "float",
					"reference": false,
					"many": false
				}
			}
		}
	}
};