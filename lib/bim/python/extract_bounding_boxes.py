#!/usr/bin/env python3
"""
Extract bounding boxes from IFC file for clash detection
"""

import ifcopenshell
import ifcopenshell.geom
import json
import sys


def extract_bounding_boxes(ifc_path):
    """Extract AABB (Axis-Aligned Bounding Box) for each element"""
    ifc_file = ifcopenshell.open(ifc_path)
    settings = ifcopenshell.geom.settings()
    settings.set(settings.USE_WORLD_COORDS, True)

    results = {}

    for element in ifc_file.by_type('IfcProduct'):
        if not element.Representation:
            continue

        try:
            shape = ifcopenshell.geom.create_shape(settings, element)
            bbox = shape.geometry.bounding_box

            results[element.GlobalId] = {
                'min': [bbox.min_x, bbox.min_y, bbox.min_z],
                'max': [bbox.max_x, bbox.max_y, bbox.max_z],
                'type': element.is_a(),
                'name': element.Name or ''
            }
        except Exception:
            # Skip elements without processable geometry
            pass

    return results


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'Usage: extract_bounding_boxes.py <ifc_file_path>'}))
        sys.exit(1)

    try:
        result = extract_bounding_boxes(sys.argv[1])
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)
