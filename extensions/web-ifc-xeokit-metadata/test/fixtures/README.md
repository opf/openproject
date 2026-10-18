# IFC test fixtures — sources and licenses

Every `.ifc` file in this directory is third-party content. Sources and
licenses are tracked below so we can comply with the originating licenses
when redistributing the OpenProject codebase.

## buildingSMART Sample-Test-Files

The three files below come from the official buildingSMART
[`Sample-Test-Files`](https://github.com/buildingSMART/Sample-Test-Files)
repository.

> © buildingSMART International Ltd. — licensed under the
> [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
>
> Full license text: <https://creativecommons.org/licenses/by/4.0/legalcode.txt>

| File in this directory          | Original path in `buildingSMART/Sample-Test-Files`                                          | Schema       |
|---------------------------------|---------------------------------------------------------------------------------------------|--------------|
| `Building-Architecture-IFC4.ifc`   | `IFC 4.0.2.1 (IFC 4)/PCERT-Sample-Scene/Building-Architecture.ifc`                          | IFC4         |
| `Building-Architecture-IFC4X3.ifc` | `IFC 4.3.2.0 (IFC4X3_ADD2)/PCERT-Sample-Scene/Building-Architecture.ifc`                    | IFC4X3_ADD2  |
| `Infra-Rail-IFC4X3.ifc`            | `IFC 4.3.2.0 (IFC4X3_ADD2)/PCERT-Sample-Scene/Infra-Rail.ifc`                               | IFC4X3_ADD2  |

The files were not modified beyond renaming.

## OpenProject `modules/bim/spec/fixtures/files/minimal.ifc`

`minimal-IFC2X3.ifc` is a copy of `modules/bim/spec/fixtures/files/minimal.ifc`,
already shipped in this repository as a BIM-module test fixture. It is a
Revit-exported IFC2X3 file. Its original provenance and license predate this
extension; see the BIM module's history for context.
