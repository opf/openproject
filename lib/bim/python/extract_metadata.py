#!/usr/bin/env python3
"""
IFC Metadata Extractor using IfcOpenShell
Extracts spatial structure, property sets, quantities, and classifications from IFC files
"""

import ifcopenshell
import ifcopenshell.geom
import json
import sys
from collections import defaultdict


def extract_spatial_structure(ifc_file):
    """Extract building spatial hierarchy: Project → Site → Building → Storey → Space"""
    structure = {}

    # Get IfcProject
    projects = ifc_file.by_type('IfcProject')
    if projects:
        project = projects[0]
        structure['IfcProject'] = {
            'global_id': project.GlobalId,
            'name': project.Name or 'Unnamed Project',
            'children': []
        }

        # Get IfcSite
        for rel in project.IsDecomposedBy:
            for site in rel.RelatedObjects:
                if site.is_a('IfcSite'):
                    site_data = {
                        'global_id': site.GlobalId,
                        'name': site.Name or 'Unnamed Site',
                        'type': 'IfcSite',
                        'children': []
                    }

                    # Get IfcBuilding
                    for site_rel in site.IsDecomposedBy:
                        for building in site_rel.RelatedObjects:
                            if building.is_a('IfcBuilding'):
                                building_data = {
                                    'global_id': building.GlobalId,
                                    'name': building.Name or 'Unnamed Building',
                                    'type': 'IfcBuilding',
                                    'children': []
                                }

                                # Get IfcBuildingStorey
                                for building_rel in building.IsDecomposedBy:
                                    for storey in building_rel.RelatedObjects:
                                        if storey.is_a('IfcBuildingStorey'):
                                            storey_data = {
                                                'global_id': storey.GlobalId,
                                                'name': storey.Name or 'Unnamed Storey',
                                                'type': 'IfcBuildingStorey',
                                                'elevation': getattr(storey, 'Elevation', None),
                                                'children': []
                                            }

                                            # Get spaces/rooms
                                            for storey_rel in storey.IsDecomposedBy:
                                                for space in storey_rel.RelatedObjects:
                                                    if space.is_a('IfcSpace'):
                                                        space_data = {
                                                            'global_id': space.GlobalId,
                                                            'name': space.Name or 'Unnamed Space',
                                                            'type': 'IfcSpace'
                                                        }
                                                        storey_data['children'].append(space_data)

                                            building_data['children'].append(storey_data)

                                site_data['children'].append(building_data)

                    structure['IfcProject']['children'].append(site_data)

    return structure


def extract_property_sets(ifc_file):
    """Extract all property sets (Psets) from IFC elements"""
    property_sets = {}

    for element in ifc_file.by_type('IfcProduct'):
        if not hasattr(element, 'IsDefinedBy'):
            continue

        element_psets = {}
        for definition in element.IsDefinedBy:
            if definition.is_a('IfcRelDefinesByProperties'):
                prop_def = definition.RelatingPropertyDefinition
                if prop_def.is_a('IfcPropertySet'):
                    pset_name = prop_def.Name
                    pset_properties = {}

                    for prop in prop_def.HasProperties:
                        if prop.is_a('IfcPropertySingleValue'):
                            pset_properties[prop.Name] = {
                                'value': str(prop.NominalValue.wrappedValue) if prop.NominalValue else None,
                                'unit': str(prop.Unit) if hasattr(prop, 'Unit') and prop.Unit else None
                            }

                    element_psets[pset_name] = pset_properties

        if element_psets:
            property_sets[element.GlobalId] = {
                'type': element.is_a(),
                'name': element.Name or 'Unnamed',
                'psets': element_psets
            }

    return property_sets


def extract_quantities(ifc_file):
    """Extract quantity takeoff data (areas, volumes, counts)"""
    quantities = {
        'totals': defaultdict(float),
        'by_type': defaultdict(lambda: {'count': 0, 'area': 0, 'volume': 0}),
        'elements': {}
    }

    for element in ifc_file.by_type('IfcProduct'):
        element_type = element.is_a()
        quantities['by_type'][element_type]['count'] += 1

        # Extract quantities from IfcElementQuantity
        if hasattr(element, 'IsDefinedBy'):
            for definition in element.IsDefinedBy:
                if definition.is_a('IfcRelDefinesByProperties'):
                    prop_def = definition.RelatingPropertyDefinition
                    if prop_def.is_a('IfcElementQuantity'):
                        elem_quantities = {}
                        for quantity in prop_def.Quantities:
                            if quantity.is_a('IfcQuantityArea'):
                                area_value = float(quantity.AreaValue)
                                elem_quantities['area'] = area_value
                                quantities['by_type'][element_type]['area'] += area_value
                                quantities['totals']['area'] += area_value
                            elif quantity.is_a('IfcQuantityVolume'):
                                volume_value = float(quantity.VolumeValue)
                                elem_quantities['volume'] = volume_value
                                quantities['by_type'][element_type]['volume'] += volume_value
                                quantities['totals']['volume'] += volume_value
                            elif quantity.is_a('IfcQuantityLength'):
                                elem_quantities['length'] = float(quantity.LengthValue)

                        if elem_quantities:
                            quantities['elements'][element.GlobalId] = {
                                'type': element_type,
                                'name': element.Name or 'Unnamed',
                                'quantities': elem_quantities
                            }

    return dict(quantities)


def extract_classifications(ifc_file):
    """Extract classification systems (Uniclass, OmniClass, etc.)"""
    classifications = defaultdict(list)

    for rel_classification in ifc_file.by_type('IfcRelAssociatesClassification'):
        classification_ref = rel_classification.RelatingClassification
        if classification_ref.is_a('IfcClassificationReference'):
            system_name = None
            if hasattr(classification_ref, 'ReferencedSource') and classification_ref.ReferencedSource:
                system_name = classification_ref.ReferencedSource.Name

            for element in rel_classification.RelatedObjects:
                if element.is_a('IfcProduct'):
                    classifications[element.GlobalId].append({
                        'system': system_name or 'Unknown',
                        'code': classification_ref.Identification or classification_ref.ItemReference,
                        'name': classification_ref.Name
                    })

    return dict(classifications)


def extract_materials(ifc_file):
    """Extract material definitions"""
    materials = {}

    for rel_material in ifc_file.by_type('IfcRelAssociatesMaterial'):
        material_select = rel_material.RelatingMaterial

        material_info = {}
        if material_select.is_a('IfcMaterial'):
            material_info = {
                'name': material_select.Name,
                'category': material_select.Category if hasattr(material_select, 'Category') else None
            }
        elif material_select.is_a('IfcMaterialLayerSetUsage'):
            layers = []
            if hasattr(material_select, 'ForLayerSet'):
                for layer in material_select.ForLayerSet.MaterialLayers:
                    layers.append({
                        'name': layer.Material.Name if layer.Material else 'Unnamed',
                        'thickness': float(layer.LayerThickness) if layer.LayerThickness else None
                    })
            material_info = {'type': 'LayerSet', 'layers': layers}

        for element in rel_material.RelatedObjects:
            if element.is_a('IfcProduct'):
                materials[element.GlobalId] = material_info

    return materials


def extract_geometry_index(ifc_file):
    """Extract bounding boxes for all elements (for clash detection)"""
    geometry_index = {}
    settings = ifcopenshell.geom.settings()
    settings.set(settings.USE_WORLD_COORDS, True)

    for element in ifc_file.by_type('IfcProduct'):
        if not element.Representation:
            continue

        try:
            shape = ifcopenshell.geom.create_shape(settings, element)
            bbox = shape.geometry.bounding_box

            geometry_index[element.GlobalId] = {
                'type': element.is_a(),
                'name': element.Name or 'Unnamed',
                'bbox': {
                    'min': [bbox.min_x, bbox.min_y, bbox.min_z],
                    'max': [bbox.max_x, bbox.max_y, bbox.max_z]
                }
            }
        except Exception as e:
            # Skip elements that can't be processed
            pass

    return geometry_index


def main():
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'Usage: extract_metadata.py <ifc_file_path>'}))
        sys.exit(1)

    ifc_path = sys.argv[1]

    try:
        ifc_file = ifcopenshell.open(ifc_path)

        metadata = {
            'spatial_structure': extract_spatial_structure(ifc_file),
            'property_sets': extract_property_sets(ifc_file),
            'quantities': extract_quantities(ifc_file),
            'classifications': extract_classifications(ifc_file),
            'materials': extract_materials(ifc_file),
            'element_index': {}, # Built from property_sets
            'geometry_index': extract_geometry_index(ifc_file)
        }

        # Build element_index from property_sets for fast lookup
        for element_id, pset_data in metadata['property_sets'].items():
            metadata['element_index'][element_id] = {
                'type': pset_data['type'],
                'name': pset_data['name'],
                'properties': {}
            }
            for pset_name, props in pset_data['psets'].items():
                for prop_name, prop_value in props.items():
                    metadata['element_index'][element_id]['properties'][f"{pset_name}.{prop_name}"] = prop_value['value']

        print(json.dumps(metadata, indent=2))

    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)


if __name__ == '__main__':
    main()
